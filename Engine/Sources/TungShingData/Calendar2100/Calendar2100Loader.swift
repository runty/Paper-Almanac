// The 1901–2100 route's event store and months (research tung-shing-calendar-1901-2100-1, R8 plan §3.2). The research
// ships the constructed months as a table, with no new-moon days before 1900-12-22, so the route takes its months from
// the table instead of rebuilding them: rebuilding the first months of 1901 would need events the research doesn't
// supply. The store holds the term days (with the context days of 1899, 1900, 2101 and 2102) and a conjunction day at
// each month start, so day facts, nearby terms and coverage work as on the other routes. Each event's root bracket is
// its whole Hong Kong civil day under the frozen K=37 clock, as on V1's file.

import TungShingCalendar
import TungShingCore

public enum Calendar2100Loader {
    /// The store's halo: every term day of 1899–2102. Conjunctions run only from 1900-12-22 to 2101-01-29, which the
    /// table's months make sufficient (`selfContainedOutputs`).
    static let haloStart = try! GregorianDate(year: 1899, month: 1, day: 1)
    static let haloEnd = try! GregorianDate(year: 2103, month: 1, day: 1)

    public static func store(_ provider: Calendar2100Provider, runtimeSHA256: String, profile: ProfileID, formatContract: ContractID,
                             civilProjection: ContractID, evidence: (model: EvidenceID, clock: EvidenceID)) throws -> EventPackStore {
        let basis = ProjectionBasis.modeled(policy: civilProjection, assumptions: [evidence.model, evidence.clock])
        func event(_ id: String, _ kind: CalendarEventKind, _ day: GregorianDate) throws -> CalendarEvent {
            let jdn = day.dayID.value + 2_440_588
            let start = try TTInstant(julianDay: jdn - 1, nanosecondsWithinDay: V1CandidateLoader.dayStartNanoseconds)
            let lastInstant = try TTInstant(julianDay: jdn, nanosecondsWithinDay: V1CandidateLoader.dayStartNanoseconds - 1)
            return try CalendarEvent(identity: try EvidenceID(id), kind: kind, nominalTT: start,
                                     rootBracket: try TTEventBracket(lowerInclusive: start, upperInclusive: lastInstant),
                                     astronomicalUncertaintyEvidence: [evidence.model],
                                     hkProjection: .definite(day, basis: basis, mappingEvidence: [evidence.clock]))
        }
        var events: [CalendarEvent] = []
        for t in provider.termDays {
            events.append(try event("cal2100.term\(t.index).\(t.date.label)", try .solarTerm(validating: t.index), t.date))
        }
        var starts = provider.months.map(\.start)
        if let last = provider.months.last { starts.append(try last.start.adding(days: Int64(last.days))) }
        for day in starts { events.append(try event("cal2100.conjunction.\(day.label)", .conjunction, day)) }
        events.sort { ($0.nominalTT, $0.kind) < ($1.nominalTT, $1.kind) }
        guard let first = events.first, let last = events.last else { throw V1CandidateLoadError.malformed("no events") }
        let identity = try PackID(digest: "sha256:" + runtimeSHA256)
        let descriptor = PackDescriptor(identity: identity, profile: profile, formatContract: formatContract, manifestEvidence: evidence.model,
                                        providerEvidence: evidence.model, dynamicsToCivilEvidence: evidence.clock, sourcePermission: .unresolved,
                                        verification: .notAssessed, acceptedDomain: .empty)
        let halo = try CivilDateInterval(startInclusive: haloStart, endExclusive: haloEnd)
        let coverage = PackCoverage(nominalOutputIntervals: try AcceptedDateDomain(intervals: [provider.domain]),
                                    dependencyIntervals: try AcceptedDateDomain(intervals: [halo]), excludedIntervals: .empty,
                                    eventTTInterval: (first.nominalTT, last.rootBracket.upperInclusive), selfContainedOutputs: true)
        return EventPackStore(descriptor: descriptor, coverage: coverage, events: events, completenessEvidence: [evidence.model],
                              projectionPolicies: [civilProjection],
                              recipeSummary: ["eventModel": "DE440S-SKYFIELD155-SCALAR-REAL-v1", "clock": "frozen K=37 (TT − reference = 8648/125 s)",
                                              "precision": "civil day", "months": "admitted month table"])
    }

    /// The table's months, in order, each with the principal-term days it contains.
    public static func months(_ provider: Calendar2100Provider) throws -> [ConstructedLunarMonth] {
        let principal = provider.termDays.filter { $0.index % 2 == 0 }.map(\.date)
        return try provider.months.map { m in
            let interval = try CivilDateInterval(startInclusive: m.start, endExclusive: try m.start.adding(days: Int64(m.days)))
            return ConstructedLunarMonth(identity: LunarMonthID(lunarYearStartingGregorianYear: Int32(m.lunarYear), month: UInt8(m.month), isLeapMonth: m.isLeap),
                                         interval: interval, principalTermDates: principal.filter { interval.contains($0) })
        }
    }
}
