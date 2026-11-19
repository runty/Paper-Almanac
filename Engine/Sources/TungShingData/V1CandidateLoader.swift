// Research V1's model-day calendar (route B, `V1-DE440S-REAL-HK8-K37-DAY-2020-2035-draft1`): 694 event civil days in
// 2018-01-01 ..< 2037-02-01 that construct every day of 2020–2035 (research `docs/handoff/v1/model-day-candidate/
// REPORT.md`). The file is the research's CANDIDATE.json, byte for byte, admitted by its SHA-256. It carries days,
// never instants: each event's root bracket is the whole Hong Kong civil day under the frozen K=37 clock, and its
// nominal instant is that day's start, which is a bound, not an estimate.

import CryptoKit
import Foundation
import TungShingCore

public enum V1CandidateLoadError: Error, Sendable, Hashable {
    case digestMismatch(actual: String)
    case malformed(String)
    case declarationMismatch(String)
}

public enum V1CandidateLoader {
    private struct File: Decodable {
        struct Clock: Decodable { let fixedOffsetSeconds: Int; let ttMinusReferenceClockSeconds: String }
        struct Event: Decodable { let date: String; let id: String; let kind: String; let termIndex: Int? }
        let profile: String
        let eventModel: String
        let clock: Clock
        let productionAdmission: Bool
        let physicalAccuracyCertified: Bool
        let targetStartInclusive: String
        let targetEndExclusive: String
        let haloStartInclusive: String
        let haloEndExclusive: String
        let events: [Event]
    }

    /// TT minus Hong Kong civil midnight's UTC, as nanoseconds after the TT Julian noon of the previous civil day:
    /// 00:00 +08:00 is 16:00 UTC the day before (4 h after that noon), and TT = UTC + 69.184 s (K = 37 s).
    static let dayStartNanoseconds: Int64 = (4 * 3_600) * 1_000_000_000 + 69_184_000_000

    /// Validates the bytes against the pinned digest and the research's declarations, and builds an unaccepted store.
    public static func load(bytes: [UInt8], profile: ProfileID, formatContract: ContractID, civilProjection: ContractID,
                            expectedSHA256: String, evidence: (model: EvidenceID, clock: EvidenceID)) throws -> EventPackStore {
        let actual = hex(Array(SHA256.hash(data: bytes)))
        guard actual == expectedSHA256 else { throw V1CandidateLoadError.digestMismatch(actual: actual) }
        let file: File
        do { file = try JSONDecoder().decode(File.self, from: Data(bytes)) } catch { throw V1CandidateLoadError.malformed(String(describing: error)) }
        guard file.profile == profile.value else { throw V1CandidateLoadError.declarationMismatch("profile") }
        guard file.eventModel == "DE440S-SKYFIELD155-SCALAR-REAL-v1" else { throw V1CandidateLoadError.declarationMismatch("eventModel") }
        guard file.clock.fixedOffsetSeconds == 28_800, file.clock.ttMinusReferenceClockSeconds == "8648/125" else {
            throw V1CandidateLoadError.declarationMismatch("clock")
        }
        guard !file.productionAdmission, !file.physicalAccuracyCertified else { throw V1CandidateLoadError.declarationMismatch("claims") }

        func date(_ label: String, _ field: String) throws -> GregorianDate {
            do { return try GregorianDate(label: label) } catch { throw V1CandidateLoadError.malformed(field) }
        }
        let target = try CivilDateInterval(startInclusive: try date(file.targetStartInclusive, "targetStartInclusive"),
                                           endExclusive: try date(file.targetEndExclusive, "targetEndExclusive"))
        let halo = try CivilDateInterval(startInclusive: try date(file.haloStartInclusive, "haloStartInclusive"),
                                         endExclusive: try date(file.haloEndExclusive, "haloEndExclusive"))
        let basis = ProjectionBasis.modeled(policy: civilProjection, assumptions: [evidence.model, evidence.clock])
        var events: [CalendarEvent] = []
        var ids = Set<String>()
        for row in file.events {
            guard ids.insert(row.id).inserted else { throw V1CandidateLoadError.malformed("duplicate event \(row.id)") }
            let day = try date(row.date, "events.date")
            guard halo.contains(day) else { throw V1CandidateLoadError.malformed("event \(row.id) outside the halo") }
            let kind: CalendarEventKind
            switch (row.kind, row.termIndex) {
            case ("conjunction", nil): kind = .conjunction
            case ("solarTerm", let index?):
                do { kind = try .solarTerm(validating: index) } catch { throw V1CandidateLoadError.malformed("term index \(index)") }
            default: throw V1CandidateLoadError.malformed("event \(row.id) kind")
            }
            let jdn = day.dayID.value + 2_440_588
            let start = try TTInstant(julianDay: jdn - 1, nanosecondsWithinDay: dayStartNanoseconds)
            let lastInstant = try TTInstant(julianDay: jdn, nanosecondsWithinDay: dayStartNanoseconds - 1)
            events.append(try CalendarEvent(identity: try EvidenceID(row.id), kind: kind, nominalTT: start,
                                            rootBracket: try TTEventBracket(lowerInclusive: start, upperInclusive: lastInstant),
                                            astronomicalUncertaintyEvidence: [evidence.model],
                                            hkProjection: .definite(day, basis: basis, mappingEvidence: [evidence.clock])))
        }
        events.sort { ($0.nominalTT, $0.kind) < ($1.nominalTT, $1.kind) }
        guard let first = events.first, let last = events.last else { throw V1CandidateLoadError.malformed("no events") }
        let identity = try PackID(digest: "sha256:" + actual)
        let descriptor = PackDescriptor(identity: identity, profile: profile, formatContract: formatContract, manifestEvidence: evidence.model,
                                        providerEvidence: evidence.model, dynamicsToCivilEvidence: evidence.clock, sourcePermission: .unresolved,
                                        verification: .notAssessed, acceptedDomain: .empty)
        let coverage = PackCoverage(nominalOutputIntervals: try AcceptedDateDomain(intervals: [target]),
                                    dependencyIntervals: try AcceptedDateDomain(intervals: [halo]), excludedIntervals: .empty,
                                    eventTTInterval: (first.nominalTT, last.rootBracket.upperInclusive), selfContainedOutputs: true)
        return EventPackStore(descriptor: descriptor, coverage: coverage, events: events, completenessEvidence: [evidence.model],
                              projectionPolicies: [civilProjection],
                              recipeSummary: ["eventModel": file.eventModel, "clock": "frozen K=37 (TT − reference = 8648/125 s)", "precision": "civil day"])
    }

    private static func hex(_ bytes: [UInt8]) -> String { bytes.map { String(format: "%02x", $0) }.joined() }
}
