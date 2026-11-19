// The E1 calendar kernel: turns a verified event set and a validated request into complete
// day, month or conversion facts, or a typed blocking report. Pure and deterministic.

import TungShingCore

public struct KernelContracts: Sendable {
    public let monthConstruction: ContractID
    public let civilProjection: ContractID
    public let dependencyClosure: ContractID
    public init(monthConstruction: ContractID, civilProjection: ContractID, dependencyClosure: ContractID) {
        self.monthConstruction = monthConstruction
        self.civilProjection = civilProjection
        self.dependencyClosure = dependencyClosure
    }
}

/// Everything calculation needs, frozen at preparation.
public struct PreparedKernelData: Sendable, Hashable {
    public let events: CalendarEventSet
    public let months: [ConstructedLunarMonth]
    /// Civil interval the prepared months and display events fully cover.
    public let covered: CivilDateInterval
    /// Ambiguous events whose every candidate date gave the same target identities (evidence).
    public let resolvedAmbiguities: [EvidenceID]
    /// Months (by first day) whose length is not settled, with the lengths the candidate projections give (empty
    /// when the closing conjunction is excluded from the accepted domain rather than ambiguous).
    public let unresolvedMonthLengths: [GregorianDate: [Int]]

    public init(events: CalendarEventSet, months: [ConstructedLunarMonth], covered: CivilDateInterval, resolvedAmbiguities: [EvidenceID] = [],
                unresolvedMonthLengths: [GregorianDate: [Int]] = [:]) {
        self.events = events
        self.months = months
        self.covered = covered
        self.resolvedAmbiguities = resolvedAmbiguities
        self.unresolvedMonthLengths = unresolvedMonthLengths
    }

    /// The same data with the length of every month whose closing conjunction `isDisputed` marked unresolved.
    public func markingMonthLengthsUnresolved(where isDisputed: (GregorianDate) -> Bool) -> PreparedKernelData {
        var unresolved = unresolvedMonthLengths
        for month in months where isDisputed(month.interval.endExclusive) && unresolved[month.interval.startInclusive] == nil {
            unresolved[month.interval.startInclusive] = []
        }
        return PreparedKernelData(events: events, months: months, covered: covered, resolvedAmbiguities: resolvedAmbiguities, unresolvedMonthLengths: unresolved)
    }
}

public enum KernelPreparation: Sendable {
    case ready(PreparedKernelData)
    case blocked([ContractIssue])
}

public enum CalendarKernel {
    /// Days of neighbouring events requested around the dates of interest. Enough for the
    /// preceding and following winter solstices plus the conjunction closing the last month.
    public static let haloDays: Int64 = 450

    /// The civil interval whose facts the request needs, before the halo.
    public static func targetInterval(for input: LocallyValidatedInput) throws -> CivilDateInterval {
        switch input {
        case .month(let ym):
            return ym.interval
        case .date(.gregorian(let d)):
            return try CivilDateInterval(startInclusive: d, endExclusive: try d.adding(days: 1))
        case .date(.lunar(let l)):
            // A lunar year begins between late January and late February and ends about 13 months later. Month m
            // (or its leap month) cannot begin before 1 January plus 29 days for each earlier month, so a late month
            // of the first lunar year a pack covers does not reach for events the pack does not hold.
            let start = try GregorianDate(year: Int(l.lunarYearStartingGregorianYear), month: 1, day: 1).adding(days: Int64(l.month - 1) * 29)
            let end = try GregorianDate(year: Int(l.lunarYearStartingGregorianYear) + 1, month: 3, day: 31)
            return try CivilDateInterval(startInclusive: start, endExclusive: end)
        }
    }

    public static func dependencyInterval(for target: CivilDateInterval) throws -> CivilDateInterval {
        try CivilDateInterval(startInclusive: try target.startInclusive.adding(days: -haloDays),
                              endExclusive: try target.endExclusive.adding(days: haloDays))
    }

    /// Days before the anchoring solstice (the start of its month) and after the closing solstice
    /// (the conjunction ending its month) that month construction depends on.
    static let anchorMargin: Int64 = 31
    /// Ambiguous construction events resolved by enumeration per request; more than this blocks.
    static let maximumResolvedAmbiguities = 4

    /// Resolves the relevant window from the solstice anchors, refuses when an uncertain
    /// projection touches it, then builds months from the definite events inside it.
    /// - Parameter lunarQuery: for a lunar→Gregorian request, the lunar date asked for. The candidate combinations of
    ///   ambiguous events must then agree on its answer only, not on every date of the lunar year's window.
    public static func prepare(events: CalendarEventSet, target: CivilDateInterval, lunarQuery: LunarDate? = nil,
                               capability: CalendarCapability, contracts: KernelContracts) -> KernelPreparation {
        var issues: [ContractIssue] = []
        var definite: [(CalendarEvent, GregorianDate)] = []
        var ambiguous: [(CalendarEvent, [GregorianDate])] = []
        var unavailable: [(CalendarEvent, ContractIssue)] = []
        var solsticeCandidates: [GregorianDate] = []

        for event in events.events {
            switch event.hkProjection {
            case .definite(let date, _, _):
                definite.append((event, date))
                if event.kind.isWinterSolstice { solsticeCandidates.append(date) }
            case .ambiguous(let dates, _):
                ambiguous.append((event, dates))
                if event.kind.isWinterSolstice { solsticeCandidates.append(contentsOf: dates) }
            case .unavailable(let reason):
                unavailable.append((event, reason))
            }
        }
        solsticeCandidates.sort()

        func missingNeighbour() -> KernelPreparation {
            .blocked([ContractIssue(contract: contracts.dependencyClosure, field: nil, code: .missingNeighbourEvent, severity: .blocking,
                                    remedies: [.installAcceptedResources], capability: capability, evidence: events.completenessEvidence)])
        }

        // Anchors: the last solstice on or before the first target date, and the first solstice at
        // least a lunar month after the last target date. A date that falls in a solstice month
        // before the solstice itself belongs to the span that solstice opens, so the closing anchor
        // must be the solstice after that one; the extra month of margin guarantees it.
        guard let before = solsticeCandidates.last(where: { $0 <= target.startInclusive }),
              let closingFloor = try? target.endExclusive.adding(days: anchorMargin),
              let after = solsticeCandidates.first(where: { $0 >= closingFloor }),
              let windowStart = try? before.adding(days: -anchorMargin),
              let windowEnd = try? after.adding(days: anchorMargin) else {
            return missingNeighbour()
        }
        func inWindow(_ d: GregorianDate) -> Bool { d >= windowStart && d <= windowEnd }

        // Uncertain projections inside the window. Events that can move a month boundary or a
        // term membership are resolved by trying every candidate combination: when all combinations
        // give the same lunar identity for every target date, the result is determinate under the
        // policy; otherwise the dates are blocked. An uncertain term date is never hidden: the day
        // facts list such an event on each candidate date with its ambiguous projection.
        var affecting: [(CalendarEvent, [GregorianDate])] = []
        for (event, dates) in ambiguous where dates.contains(where: inWindow) {
            if event.kind == .conjunction || event.kind.isPrincipalTerm {
                affecting.append((event, dates))
            }
        }
        func uncertainIssue(_ event: CalendarEvent) -> ContractIssue {
            ContractIssue(contract: contracts.civilProjection, field: nil, code: .uncertainCivilProjection, severity: .blocking,
                          remedies: [.inspectEvidence, .chooseAcceptedDate], capability: capability,
                          evidence: [event.identity] + event.astronomicalUncertaintyEvidence)
        }
        // Events without any civil projection are placed by TT between the window's definite events.
        let windowDefinite = definite.filter { inWindow($0.1) }
        if let lowTT = windowDefinite.map({ $0.0.nominalTT }).min(), let highTT = windowDefinite.map({ $0.0.nominalTT }).max() {
            for (event, reason) in unavailable where event.nominalTT >= lowTT && event.nominalTT <= highTT {
                issues.append(reason)
            }
        }
        if !issues.isEmpty { return .blocked(issues) }
        guard affecting.count <= maximumResolvedAmbiguities else {
            return .blocked(affecting.map { uncertainIssue($0.0) })
        }

        // Candidate combinations, in a fixed order; the first is the earliest date of every event.
        var combinations: [[GregorianDate]] = [[]]
        for (_, dates) in affecting {
            combinations = combinations.flatMap { prefix in dates.map { prefix + [$0] } }
        }

        /// What every candidate combination must agree on: the target's lunar identities, or a lunar query's answer.
        enum Signature: Hashable {
            case identities([LunarDate])
            case found(GregorianDate)
            case nonexistentMonth
            case impossibleDay(Int)
        }
        var firstMonths: [ConstructedLunarMonth]? = nil
        var signature: Signature? = nil
        /// The lengths each combination gives the months holding the dates of interest, by month start.
        var lengths: [GregorianDate: Set<Int>] = [:]
        for combination in combinations {
            var conjunctions: [GregorianDate] = []
            var principal: [GregorianDate] = []
            var solstices: [GregorianDate] = []
            for (event, date) in windowDefinite {
                switch event.kind {
                case .conjunction: conjunctions.append(date)
                case .solarTerm:
                    if event.kind.isPrincipalTerm { principal.append(date) }
                    if event.kind.isWinterSolstice { solstices.append(date) }
                }
            }
            for ((event, _), date) in zip(affecting, combination) {
                switch event.kind {
                case .conjunction: conjunctions.append(date)
                case .solarTerm:
                    if event.kind.isPrincipalTerm { principal.append(date) }
                    if event.kind.isWinterSolstice { solstices.append(date) }
                }
            }
            conjunctions.sort(); principal.sort(); solstices.sort()

            let months: [ConstructedLunarMonth]
            do {
                months = try MonthConstruction.construct(.init(conjunctionDates: conjunctions, principalTermDates: principal, winterSolsticeDates: solstices))
            } catch let failure as MonthConstructionFailure {
                switch failure {
                case .missingNeighbourEvent: return missingNeighbour()
                case .invalidSpanStructure, .invalidCadence:
                    issues.append(ContractIssue(contract: contracts.monthConstruction, field: nil, code: .invalidResource, severity: .blocking,
                                                remedies: [.installAcceptedResources, .inspectEvidence], capability: capability,
                                                evidence: events.completenessEvidence))
                    return .blocked(issues)
                }
            } catch {
                issues.append(ContractIssue(contract: contracts.monthConstruction, field: nil, code: .invalidResource, severity: .blocking, remedies: [.inspectEvidence], capability: capability))
                return .blocked(issues)
            }

            // Every target date must fall inside a constructed month (construct() only emits complete spans).
            guard let firstMonth = months.first, let lastMonth = months.last,
                  firstMonth.interval.startInclusive <= target.startInclusive,
                  target.endExclusive <= lastMonth.interval.endExclusive else {
                return missingNeighbour()
            }
            let current: Signature
            let interest: [GregorianDate]
            if let lunarQuery {
                switch MonthConstruction.gregorianDate(for: lunarQuery, in: months) {
                case .found(let date, _): current = .found(date); interest = [date]
                case .nonexistentMonth: current = .nonexistentMonth; interest = []
                case .impossibleDay(let length): current = .impossibleDay(length); interest = []
                }
            } else {
                let identities = target.dates.compactMap { MonthConstruction.lunarDate(for: $0, in: months)?.0 }
                guard identities.count == target.dayCount else { return missingNeighbour() }
                current = .identities(identities)
                interest = target.dates
            }
            if let signature {
                if signature != current {
                    return .blocked(affecting.map { uncertainIssue($0.0) })
                }
            } else {
                signature = current
                firstMonths = months
            }
            // A month's length follows its closing conjunction: the same identities can come with different lengths.
            for date in interest {
                if let (_, month) = MonthConstruction.lunarDate(for: date, in: months) {
                    lengths[month.interval.startInclusive, default: []].insert(month.length)
                }
            }
        }
        guard let months = firstMonths, let firstMonth = months.first, let lastMonth = months.last else { return missingNeighbour() }
        let covered = try! CivilDateInterval(startInclusive: firstMonth.interval.startInclusive, endExclusive: lastMonth.interval.endExclusive)
        let unresolved = lengths.filter { $0.value.count > 1 }.mapValues { $0.sorted() }
        return .ready(PreparedKernelData(events: events, months: months, covered: covered,
                                         resolvedAmbiguities: affecting.map { $0.0.identity }, unresolvedMonthLengths: unresolved))
    }

    public static func dayFacts(for date: GregorianDate, data: PreparedKernelData) -> CalendarDayFacts? {
        guard let (lunar, month) = MonthConstruction.lunarDate(for: date, in: data.months) else { return nil }
        let onDate = data.events.events.filter { event in
            switch event.hkProjection {
            case .definite(let d, _, _): return d == date
            case .ambiguous(let dates, _): return dates.contains(date)
            case .unavailable: return false
            }
        }
        let window = CalendarDayFacts.nearbyTermWindowDays
        var nearby: [SolarTermDate] = []
        var uncertain: [EvidenceID] = []
        var uncertainDates: [UncertainSolarTermDates] = []
        for event in data.events.events {
            guard case .solarTerm(let index) = event.kind else { continue }
            switch event.hkProjection {
            case .definite(let d, _, _):
                if abs(d.days(since: date)) <= window { nearby.append(SolarTermDate(indexFromMarchEquinox: index, date: d, event: event.identity)) }
            case .ambiguous(let dates, _):
                if dates.contains(where: { abs($0.days(since: date)) <= window }) {
                    uncertain.append(event.identity)
                    uncertainDates.append(UncertainSolarTermDates(indexFromMarchEquinox: index, candidates: dates, event: event.identity))
                }
            case .unavailable:
                continue
            }
        }
        nearby.sort()
        uncertain.sort()
        uncertainDates.sort()
        let unresolved = data.unresolvedMonthLengths[month.interval.startInclusive]
        return CalendarDayFacts(gregorian: date, lunarIdentity: lunar, lunarMonthLength: unresolved == nil ? UInt8(month.length) : nil,
                                lunarMonthLengthCandidates: (unresolved ?? []).map { UInt8($0) }, events: onDate,
                                nearbyTerms: nearby, uncertainNearbyTerms: uncertain, uncertainNearbyTermDates: uncertainDates)
    }

    public static func monthFacts(for month: GregorianYearMonth, data: PreparedKernelData) -> [CalendarDayFacts]? {
        var out: [CalendarDayFacts] = []
        for date in month.interval.dates {
            guard let facts = dayFacts(for: date, data: data) else { return nil }
            out.append(facts)
        }
        return out
    }

    public enum ConversionResult: Sendable, Hashable {
        case identity(CalendarIdentityPair)
        case nonexistentLunarMonth
        case impossibleLunarDay(monthLength: Int)
        case outsideCoverage
    }

    public static func convert(_ input: ValidatedDateInput, data: PreparedKernelData) -> ConversionResult {
        switch input {
        case .gregorian(let g):
            guard let (lunar, _) = MonthConstruction.lunarDate(for: g, in: data.months) else { return .outsideCoverage }
            return .identity(CalendarIdentityPair(gregorian: g, lunar: lunar))
        case .lunar(let l):
            switch MonthConstruction.gregorianDate(for: l, in: data.months) {
            case .found(let g, _): return .identity(CalendarIdentityPair(gregorian: g, lunar: l))
            case .nonexistentMonth: return .nonexistentLunarMonth
            case .impossibleDay(let len): return .impossibleLunarDay(monthLength: len)
            }
        }
    }
}
