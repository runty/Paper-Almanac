// Astronomical calendar events as supplied by a verified offline pack.

public enum ProjectionBasis: Sendable, Hashable {
    case modeled(policy: ContractID, assumptions: [EvidenceID])
    case authoritativePublication(source: EvidenceID)
}

/// Definite means determinate under the identified accepted policy, never unconditional accuracy.
public enum HKCivilDateProjection: Sendable, Hashable {
    case definite(GregorianDate, basis: ProjectionBasis, mappingEvidence: [EvidenceID])
    case ambiguous([GregorianDate], mappingEvidence: [EvidenceID])
    case unavailable(reason: ContractIssue)

    public var definiteDate: GregorianDate? {
        if case .definite(let date, _, _) = self { return date }
        return nil
    }
}

public enum CalendarEventKind: Sendable, Hashable, Comparable {
    case conjunction
    /// 0…23 at 15° spacing from the March equinox; even indices are principal terms (中氣); 18 is the winter solstice.
    case solarTerm(indexFromMarchEquinox: UInt8)

    public static func solarTerm(validating index: Int) throws -> CalendarEventKind {
        guard (0...23).contains(index) else { throw CoreValidationError.invalidTermIndex(index) }
        return .solarTerm(indexFromMarchEquinox: UInt8(index))
    }

    public var isPrincipalTerm: Bool {
        if case .solarTerm(let i) = self { return i % 2 == 0 }
        return false
    }

    public var isWinterSolstice: Bool {
        if case .solarTerm(let i) = self { return i == 18 }
        return false
    }

    /// Sort order for ties: conjunction before solarTerm, then by index.
    private var rank: Int {
        switch self {
        case .conjunction: return -1
        case .solarTerm(let i): return Int(i)
        }
    }

    public static func < (lhs: CalendarEventKind, rhs: CalendarEventKind) -> Bool { lhs.rank < rhs.rank }
}

public struct CalendarEvent: Sendable, Hashable {
    public let identity: EvidenceID
    public let kind: CalendarEventKind
    public let nominalTT: TTInstant
    public let rootBracket: TTEventBracket
    /// Ordered evidence for the event's astronomical uncertainty (model, event definition).
    public let astronomicalUncertaintyEvidence: [EvidenceID]
    public let hkProjection: HKCivilDateProjection

    public init(identity: EvidenceID, kind: CalendarEventKind, nominalTT: TTInstant, rootBracket: TTEventBracket,
                astronomicalUncertaintyEvidence: [EvidenceID], hkProjection: HKCivilDateProjection) throws {
        guard rootBracket.encloses(nominalTT) else { throw CoreValidationError.invalidBracket }
        self.identity = identity
        self.kind = kind
        self.nominalTT = nominalTT
        self.rootBracket = rootBracket
        self.astronomicalUncertaintyEvidence = astronomicalUncertaintyEvidence
        self.hkProjection = hkProjection
    }
}

public struct CalendarEventSet: Sendable, Hashable {
    public let pack: PackID
    public let profile: ProfileID
    /// Sorted by TT, then kind.
    public let events: [CalendarEvent]
    public let completenessEvidence: [EvidenceID]

    public init(pack: PackID, profile: ProfileID, events: [CalendarEvent], completenessEvidence: [EvidenceID]) {
        self.pack = pack
        self.profile = profile
        self.events = events
        self.completenessEvidence = completenessEvidence
    }
}

public struct PackDescriptor: Sendable, Hashable {
    public let identity: PackID
    public let profile: ProfileID
    public let formatContract: ContractID
    public let manifestEvidence: EvidenceID
    public let providerEvidence: EvidenceID
    public let dynamicsToCivilEvidence: EvidenceID
    public let sourcePermission: SourcePermissionStatus
    public let verification: VerificationStatus
    /// The domain the installation's acceptance record enables; empty when not accepted.
    public let acceptedDomain: AcceptedDateDomain

    public init(identity: PackID, profile: ProfileID, formatContract: ContractID, manifestEvidence: EvidenceID,
                providerEvidence: EvidenceID, dynamicsToCivilEvidence: EvidenceID, sourcePermission: SourcePermissionStatus,
                verification: VerificationStatus, acceptedDomain: AcceptedDateDomain) {
        self.identity = identity
        self.profile = profile
        self.formatContract = formatContract
        self.manifestEvidence = manifestEvidence
        self.providerEvidence = providerEvidence
        self.dynamicsToCivilEvidence = dynamicsToCivilEvidence
        self.sourcePermission = sourcePermission
        self.verification = verification
        self.acceptedDomain = acceptedDomain
    }
}

public enum PackCoverageFailure: Error, Sendable, Hashable {
    case incomplete([ContractIssue])
}

/// A verified, immutable event store. `dependencyClosure` returns every event needed for the
/// requested dates or throws `PackCoverageFailure`; it never truncates.
public protocol VerifiedEventPack: Sendable {
    var descriptor: PackDescriptor { get }
    func dependencyClosure(for dates: CivilDateInterval) throws -> CalendarEventSet
}

public protocol EventPackLoader: Sendable {
    associatedtype Pack: VerifiedEventPack
    @concurrent func loadAndValidate(bytes: [UInt8], expected: PackID) async throws -> Pack
}
