// The table route's preparation (R8 plan §3.2): the 1901–2100 calendar's months come from the admitted table, never
// rebuilt, so a request takes the months that cover its target and the events the store selected for it.

import TungShingCore

extension CalendarKernel {
    /// The months of `table` (in order) meeting `target`, with the events of the target's window. Nothing is
    /// extrapolated: a Gregorian target lies inside the domain, which the table covers, and a lunar year's window that
    /// starts before the table (lunar 1900) takes the months the table has; its answer is checked against the domain
    /// after conversion, as on every route.
    public static func prepare(events: CalendarEventSet, table: [ConstructedLunarMonth], target: CivilDateInterval,
                               capability: CalendarCapability, contracts: KernelContracts) -> KernelPreparation {
        let months = table.filter { $0.interval.endExclusive > target.startInclusive && $0.interval.startInclusive < target.endExclusive }
        guard let first = months.first, let last = months.last,
              let covered = try? CivilDateInterval(startInclusive: first.interval.startInclusive, endExclusive: last.interval.endExclusive) else {
            return .blocked([ContractIssue(contract: contracts.dependencyClosure, field: nil, code: .missingNeighbourEvent, severity: .blocking,
                                           remedies: [.installAcceptedResources], capability: capability)])
        }
        return .ready(PreparedKernelData(events: events, months: months, covered: covered))
    }
}
