// Preparation outcomes, snapshots, evidence and the public engine protocol.

public enum CoverageState: Sendable, Hashable {
    case complete
    case unknown(dependencies: [ContractIssue])
    case unsupported(contract: ContractID)
    case calculationError(evidence: [EvidenceID])
}

public struct CapabilityCoverage: Sendable, Hashable {
    public let capability: CalendarCapability
    public let state: CoverageState
    public init(capability: CalendarCapability, state: CoverageState) {
        self.capability = capability
        self.state = state
    }
}

public struct PreparedMetadata: Sendable, Hashable {
    public let original: CalendarRequestDraft
    public let normalizedInput: LocallyValidatedInput
    public let catalogue: CatalogueID
    public let calculation: CalculationID
    public let packs: [PackID]
    public let decisions: [ResolvedDecisionReference]
    public let plannedCoverage: [CapabilityCoverage]

    public init(original: CalendarRequestDraft, normalizedInput: LocallyValidatedInput, catalogue: CatalogueID,
                calculation: CalculationID, packs: [PackID], decisions: [ResolvedDecisionReference],
                plannedCoverage: [CapabilityCoverage]) {
        self.original = original
        self.normalizedInput = normalizedInput
        self.catalogue = catalogue
        self.calculation = calculation
        self.packs = packs
        self.decisions = decisions
        self.plannedCoverage = plannedCoverage
    }
}

/// Production conformance is engine-owned and opaque; clients cannot forge a trusted plan.
public protocol PreparedCalendarCalculation: Sendable {
    var metadata: PreparedMetadata { get }
}

public enum PreparationOutcome<Plan: PreparedCalendarCalculation>: Sendable {
    case ready(Plan)
    case blocked(ValidationReport)
}

public struct CalendarIdentityPair: Sendable, Hashable {
    public let gregorian: GregorianDate
    public let lunar: LunarDate
    public init(gregorian: GregorianDate, lunar: LunarDate) {
        self.gregorian = gregorian
        self.lunar = lunar
    }
}

/// A solar term with a definite Hong Kong civil date, as carried by the provider.
public struct SolarTermDate: Sendable, Hashable, Comparable {
    public let indexFromMarchEquinox: UInt8
    public let date: GregorianDate
    public let event: EvidenceID

    public init(indexFromMarchEquinox: UInt8, date: GregorianDate, event: EvidenceID) {
        self.indexFromMarchEquinox = indexFromMarchEquinox
        self.date = date
        self.event = event
    }

    public static func < (lhs: SolarTermDate, rhs: SolarTermDate) -> Bool {
        (lhs.date, lhs.indexFromMarchEquinox) < (rhs.date, rhs.indexFromMarchEquinox)
    }
}

/// A solar term whose civil day is not definite under the accepted projection policy: the lunar identity may
/// be stable, but the term's membership is one of `candidates` (research review §3). Displays name it with every
/// candidate; nothing places it on one day.
public struct UncertainSolarTermDates: Sendable, Hashable, Comparable {
    public let indexFromMarchEquinox: UInt8
    /// Candidate civil dates, ascending; at least two.
    public let candidates: [GregorianDate]
    public let event: EvidenceID

    public init(indexFromMarchEquinox: UInt8, candidates: [GregorianDate], event: EvidenceID) {
        self.indexFromMarchEquinox = indexFromMarchEquinox
        self.candidates = candidates.sorted()
        self.event = event
    }

    public static func < (lhs: UncertainSolarTermDates, rhs: UncertainSolarTermDates) -> Bool {
        (lhs.candidates.first ?? lhs.candidates[0], lhs.indexFromMarchEquinox) < (rhs.candidates.first ?? rhs.candidates[0], rhs.indexFromMarchEquinox)
    }
}

public struct CalendarDayFacts: Sendable, Hashable {
    /// Days either side of the date whose definite solar terms are carried for almanac consumers.
    public static let nearbyTermWindowDays: Int64 = 80

    public let gregorian: GregorianDate
    public let lunarIdentity: LunarDate
    /// 29 or 30; nil when the month's closing conjunction is not settled (an ambiguous projection whose candidates
    /// give different lengths, or a conjunction in an excluded part of the accepted domain). Never guessed.
    public let lunarMonthLength: UInt8?
    /// The lengths the candidate projections give when `lunarMonthLength` is nil; empty when they are not known.
    public let lunarMonthLengthCandidates: [UInt8]
    /// Complete event list on this date; each event's clock precision is evidence.
    public let events: [CalendarEvent]
    /// Definite solar-term dates within `nearbyTermWindowDays` of the date, sorted; reviewed
    /// provider facts carried for term-dependent consumers (solar month, season, term-adjacent days).
    public let nearbyTerms: [SolarTermDate]
    /// Solar terms in the same window whose civil date is not definite; consumers needing them block.
    public let uncertainNearbyTerms: [EvidenceID]
    /// The same uncertain terms with their candidate dates, for displays that must name them honestly.
    public let uncertainNearbyTermDates: [UncertainSolarTermDates]

    public init(gregorian: GregorianDate, lunarIdentity: LunarDate, lunarMonthLength: UInt8?, lunarMonthLengthCandidates: [UInt8] = [], events: [CalendarEvent],
                nearbyTerms: [SolarTermDate] = [], uncertainNearbyTerms: [EvidenceID] = [], uncertainNearbyTermDates: [UncertainSolarTermDates] = []) {
        self.gregorian = gregorian
        self.lunarIdentity = lunarIdentity
        self.lunarMonthLength = lunarMonthLength
        self.lunarMonthLengthCandidates = lunarMonthLength == nil ? lunarMonthLengthCandidates.sorted() : []
        self.events = events
        self.nearbyTerms = nearbyTerms
        self.uncertainNearbyTerms = uncertainNearbyTerms
        self.uncertainNearbyTermDates = uncertainNearbyTermDates
    }
}

public enum CalendarFactValidity: Sendable, Hashable {
    case civilDate(GregorianDate)
    case civilDateInterval(CivilDateInterval)
}

public struct SourceEvidenceReference: Sendable, Hashable {
    public let identity: EvidenceID
    public let pack: PackID
    public let locator: String
    public init(identity: EvidenceID, pack: PackID, locator: String) {
        self.identity = identity
        self.pack = pack
        self.locator = locator
    }
}

public struct DerivationEvidence: Sendable, Hashable {
    public let identity: EvidenceID
    public let contract: ContractID
    public let dependencies: [EvidenceID]
    public let sourceEvidence: [EvidenceID]
    public init(identity: EvidenceID, contract: ContractID, dependencies: [EvidenceID], sourceEvidence: [EvidenceID]) {
        self.identity = identity
        self.contract = contract
        self.dependencies = dependencies
        self.sourceEvidence = sourceEvidence
    }
}

public struct SnapshotContext: Sendable, Hashable {
    public let result: ResultID
    public let prepared: PreparedMetadata
    public let coverage: [CapabilityCoverage]
    public let validity: CalendarFactValidity
    public let evidenceGraph: [DerivationEvidence]
    public let sourceEvidence: [SourceEvidenceReference]

    public init(result: ResultID, prepared: PreparedMetadata, coverage: [CapabilityCoverage], validity: CalendarFactValidity,
                evidenceGraph: [DerivationEvidence], sourceEvidence: [SourceEvidenceReference]) {
        self.result = result
        self.prepared = prepared
        self.coverage = coverage
        self.validity = validity
        self.evidenceGraph = evidenceGraph
        self.sourceEvidence = sourceEvidence
    }
}

public struct CalendarDaySnapshot: Sendable, Hashable {
    public let context: SnapshotContext
    public let facts: CalendarDayFacts
    public init(context: SnapshotContext, facts: CalendarDayFacts) { self.context = context; self.facts = facts }
}

public struct CalendarConversionSnapshot: Sendable, Hashable {
    public let context: SnapshotContext
    public let identity: CalendarIdentityPair
    public init(context: SnapshotContext, identity: CalendarIdentityPair) { self.context = context; self.identity = identity }
}

public struct CalendarMonthSnapshot: Sendable, Hashable {
    public let context: SnapshotContext
    public let month: GregorianYearMonth
    /// Every date of the requested month in ascending order; never partial.
    public let days: [CalendarDayFacts]
    public init(context: SnapshotContext, month: GregorianYearMonth, days: [CalendarDayFacts]) {
        self.context = context
        self.month = month
        self.days = days
    }
}

public enum CalendarSnapshot: Sendable, Hashable {
    case day(CalendarDaySnapshot)
    case conversion(CalendarConversionSnapshot)
    case month(CalendarMonthSnapshot)

    public var context: SnapshotContext {
        switch self {
        case .day(let s): return s.context
        case .conversion(let s): return s.context
        case .month(let s): return s.context
        }
    }
}

/// Operational failures. Expected data conditions are reports, not errors.
public enum EngineFailure: Error, Sendable, Hashable {
    case resourceRead
    case resourceLimit
    case integrityRejection
    case incompatiblePreparedAlgorithm
    case numericalInvariant(contract: ContractID)
    case serializationRejection(contract: ContractID)
}

public protocol CalendarEngineAPI: Actor {
    associatedtype Plan: PreparedCalendarCalculation
    func catalogue() -> CapabilityCatalogue
    func requirements(for request: CalendarRequestDraft) -> RequirementAssessment
    func validate(_ request: CalendarRequestDraft) -> ValidationReport
    func prepare(_ request: CalendarRequestDraft) async throws -> PreparationOutcome<Plan>
    func calculate(_ prepared: Plan) async throws -> CalendarSnapshot
}

public protocol CalendarCalculationKernel: Sendable {
    associatedtype Plan: PreparedCalendarCalculation
    @concurrent func calculate(_ prepared: Plan) async throws -> CalendarSnapshot
}
