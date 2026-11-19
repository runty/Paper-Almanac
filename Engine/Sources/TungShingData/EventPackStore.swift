// Immutable verified event store and the external acceptance record.

import TungShingCore
import TungShingCalendar

/// Checked-in reviewed release configuration that admits one exact pack digest.
public struct PackAcceptanceRecord: Sendable, Hashable {
    public let packDigest: PackID
    public let profile: ProfileID
    public let algorithmRevision: String
    public let researchCommit: String
    public let projectionPolicy: ContractID
    public let verificationReportDigest: String
    public let allowedUses: [String]
    public let acceptedDateIntervals: AcceptedDateDomain
    public let exclusions: AcceptedDateDomain
    public let reviewIdentity: String

    public init(packDigest: PackID, profile: ProfileID, algorithmRevision: String, researchCommit: String,
                projectionPolicy: ContractID, verificationReportDigest: String, allowedUses: [String],
                acceptedDateIntervals: AcceptedDateDomain, exclusions: AcceptedDateDomain, reviewIdentity: String) {
        self.packDigest = packDigest
        self.profile = profile
        self.algorithmRevision = algorithmRevision
        self.researchCommit = researchCommit
        self.projectionPolicy = projectionPolicy
        self.verificationReportDigest = verificationReportDigest
        self.allowedUses = allowedUses
        self.acceptedDateIntervals = acceptedDateIntervals
        self.exclusions = exclusions
        self.reviewIdentity = reviewIdentity
    }

    /// Accepted minus exclusions, as a domain.
    public func enabledDomain() throws -> AcceptedDateDomain {
        var result: [CivilDateInterval] = []
        for interval in acceptedDateIntervals.intervals {
            var pieces = [interval]
            for ex in exclusions.intervals {
                var next: [CivilDateInterval] = []
                for p in pieces {
                    if ex.endExclusive <= p.startInclusive || ex.startInclusive >= p.endExclusive { next.append(p); continue }
                    if ex.startInclusive > p.startInclusive { next.append(try CivilDateInterval(startInclusive: p.startInclusive, endExclusive: ex.startInclusive)) }
                    if ex.endExclusive < p.endExclusive { next.append(try CivilDateInterval(startInclusive: ex.endExclusive, endExclusive: p.endExclusive)) }
                }
                pieces = next
            }
            result.append(contentsOf: pieces)
        }
        return try AcceptedDateDomain(intervals: result)
    }
}

public enum PackAdmissionError: Error, Sendable, Hashable {
    case digestMismatch(expected: String, actual: String)
    case profileMismatch
    case algorithmRevisionMismatch
    case projectionPolicyMismatch
}

/// The pack's own declarations, validated at load.
public struct PackCoverage: Sendable, Hashable {
    public let nominalOutputIntervals: AcceptedDateDomain
    public let dependencyIntervals: AcceptedDateDomain
    public let excludedIntervals: AcceptedDateDomain
    public let eventTTInterval: (lower: TTInstant, upper: TTInstant)
    /// The pack declares that its dependency intervals hold every event any nominal output date needs (research V1 R01
    /// verified this for every day), so a request inside the outputs is served from them even where the kernel's
    /// generic halo reaches past them.
    public let selfContainedOutputs: Bool

    public static func == (lhs: PackCoverage, rhs: PackCoverage) -> Bool {
        lhs.nominalOutputIntervals == rhs.nominalOutputIntervals && lhs.dependencyIntervals == rhs.dependencyIntervals
            && lhs.excludedIntervals == rhs.excludedIntervals && lhs.eventTTInterval.lower == rhs.eventTTInterval.lower && lhs.eventTTInterval.upper == rhs.eventTTInterval.upper
            && lhs.selfContainedOutputs == rhs.selfContainedOutputs
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(nominalOutputIntervals); hasher.combine(dependencyIntervals); hasher.combine(excludedIntervals)
        hasher.combine(eventTTInterval.lower); hasher.combine(eventTTInterval.upper); hasher.combine(selfContainedOutputs)
    }

    public init(nominalOutputIntervals: AcceptedDateDomain, dependencyIntervals: AcceptedDateDomain, excludedIntervals: AcceptedDateDomain,
                eventTTInterval: (lower: TTInstant, upper: TTInstant), selfContainedOutputs: Bool = false) {
        self.nominalOutputIntervals = nominalOutputIntervals
        self.dependencyIntervals = dependencyIntervals
        self.excludedIntervals = excludedIntervals
        self.eventTTInterval = eventTTInterval
        self.selfContainedOutputs = selfContainedOutputs
    }
}

public struct EventPackStore: VerifiedEventPack, Hashable {
    public let descriptor: PackDescriptor
    public let coverage: PackCoverage
    /// Sorted by TT, then kind.
    public let events: [CalendarEvent]
    public let completenessEvidence: [EvidenceID]
    public let projectionPolicies: Set<ContractID>
    public let recipeSummary: [String: String]
    /// For each ambiguous event, its date under each named scenario (the evidence behind "possible on either day").
    public let scenarioDates: [EvidenceID: [String: [GregorianDate]]]

    public init(descriptor: PackDescriptor, coverage: PackCoverage, events: [CalendarEvent], completenessEvidence: [EvidenceID], projectionPolicies: Set<ContractID>,
                recipeSummary: [String: String], scenarioDates: [EvidenceID: [String: [GregorianDate]]] = [:]) {
        self.descriptor = descriptor
        self.coverage = coverage
        self.events = events
        self.completenessEvidence = completenessEvidence
        self.projectionPolicies = projectionPolicies
        self.recipeSummary = recipeSummary
        self.scenarioDates = scenarioDates
    }

    /// The source permission a record grants a build made for `use`: permitted only when the record names that use,
    /// restricted when it names others (the sources are cleared for those alone), unresolved when it names none.
    public static func sourcePermission(for record: PackAcceptanceRecord, use: ProductUse, evidence: [EvidenceID]) -> SourcePermissionStatus {
        if record.allowedUses.isEmpty { return .unresolved }
        return record.allowedUses.contains(use.rawValue) ? .permitted(evidence: evidence) : .restricted(evidence: evidence)
    }

    /// Returns a new store whose descriptor carries the acceptance for a build made for `use`; the events are unchanged.
    public func accepting(_ record: PackAcceptanceRecord, manifestEvidence: EvidenceID, expectedAlgorithmRevision: String, use: ProductUse) throws -> EventPackStore {
        guard record.packDigest == descriptor.identity else {
            throw PackAdmissionError.digestMismatch(expected: record.packDigest.digest, actual: descriptor.identity.digest)
        }
        guard record.profile == descriptor.profile else { throw PackAdmissionError.profileMismatch }
        guard record.algorithmRevision == expectedAlgorithmRevision else { throw PackAdmissionError.algorithmRevisionMismatch }
        guard projectionPolicies.contains(record.projectionPolicy) else { throw PackAdmissionError.projectionPolicyMismatch }
        // Enabled domain is the acceptance domain intersected with the pack's nominal output intervals.
        let enabled = try record.enabledDomain()
        var intersected: [CivilDateInterval] = []
        for a in enabled.intervals {
            for b in coverage.nominalOutputIntervals.intervals {
                let s = max(a.startInclusive, b.startInclusive)
                let e = min(a.endExclusive, b.endExclusive)
                if s < e { intersected.append(try CivilDateInterval(startInclusive: s, endExclusive: e)) }
            }
        }
        let domain = try AcceptedDateDomain(intervals: intersected)
        let permittedEvidence = try EvidenceID("acceptance.reuse.\(record.reviewIdentity.filter { $0.isLetter || $0.isNumber })")
        let descriptor = PackDescriptor(
            identity: descriptor.identity, profile: descriptor.profile, formatContract: descriptor.formatContract,
            manifestEvidence: manifestEvidence, providerEvidence: descriptor.providerEvidence,
            dynamicsToCivilEvidence: descriptor.dynamicsToCivilEvidence,
            sourcePermission: Self.sourcePermission(for: record, use: use, evidence: [permittedEvidence]),
            verification: .accepted(manifest: manifestEvidence),
            acceptedDomain: domain)
        return EventPackStore(descriptor: descriptor, coverage: coverage, events: events, completenessEvidence: completenessEvidence, projectionPolicies: projectionPolicies,
                              recipeSummary: recipeSummary, scenarioDates: scenarioDates)
    }

    /// Returns all events whose nominal or candidate civil dates fall in the halo around `dates`,
    /// provided the pack declares dependency coverage for that whole range.
    public func dependencyClosure(for dates: CivilDateInterval) throws -> CalendarEventSet {
        var window = try CalendarKernel.dependencyInterval(for: dates)
        if coverage.selfContainedOutputs, coverage.nominalOutputIntervals.contains(dates),
           let held = coverage.dependencyIntervals.intervals.first(where: { $0.contains(dates.startInclusive) }) {
            window = try CivilDateInterval(startInclusive: max(window.startInclusive, held.startInclusive), endExclusive: min(window.endExclusive, held.endExclusive))
        }
        guard coverage.dependencyIntervals.contains(window) else {
            let issue = ContractIssue(contract: descriptor.formatContract, field: nil, code: .missingNeighbourEvent, severity: .blocking,
                                      remedies: [.installAcceptedResources, .chooseAcceptedDate], capability: .hkCalendarIdentity,
                                      evidence: completenessEvidence)
            throw PackCoverageFailure.incomplete([issue])
        }
        let selected = events.filter { event in
            switch event.hkProjection {
            case .definite(let d, _, _): return window.contains(d)
            case .ambiguous(let ds, _): return ds.contains { window.contains($0) }
            case .unavailable: return false
            }
        }
        return CalendarEventSet(pack: descriptor.identity, profile: descriptor.profile, events: selected, completenessEvidence: completenessEvidence)
    }
}
