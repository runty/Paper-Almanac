// Pure lunar month construction from civil event dates. No instants, no clocks, no interpretation.
// Rules follow docs/design/PHASE_1_ENGINE.md §6 and the research calendar foundation.

import TungShingCore

/// A constructed lunar month: `[start, end)` civil dates with its identity.
public struct ConstructedLunarMonth: Sendable, Hashable {
    public let identity: LunarMonthID
    public let interval: CivilDateInterval
    /// Principal-term civil dates falling inside the month (by date membership).
    public let principalTermDates: [GregorianDate]

    public init(identity: LunarMonthID, interval: CivilDateInterval, principalTermDates: [GregorianDate]) {
        self.identity = identity
        self.interval = interval
        self.principalTermDates = principalTermDates
    }

    public var length: Int { Int(interval.dayCount) }

    public func contains(_ date: GregorianDate) -> Bool { interval.contains(date) }
}

public enum MonthConstructionFailure: Error, Sendable, Hashable {
    /// A required neighbouring event (solstice anchor or conjunction) is missing from the supplied dates.
    case missingNeighbourEvent(detail: String)
    /// Span structure is impossible (not 12 or 13 months, or no eligible leap month).
    case invalidSpanStructure(detail: String)
    /// Month length outside 29…30 days or non-increasing conjunction dates.
    case invalidCadence(detail: String)
}

public enum MonthConstruction {
    /// Civil-date inputs for construction. Conjunction and solstice dates must be strictly increasing.
    public struct Inputs: Sendable {
        public let conjunctionDates: [GregorianDate]
        public let principalTermDates: [GregorianDate]
        public let winterSolsticeDates: [GregorianDate]

        public init(conjunctionDates: [GregorianDate], principalTermDates: [GregorianDate], winterSolsticeDates: [GregorianDate]) {
            self.conjunctionDates = conjunctionDates
            self.principalTermDates = principalTermDates
            self.winterSolsticeDates = winterSolsticeDates
        }
    }

    /// Builds every complete lunar month between consecutive winter-solstice anchors that the inputs allow.
    /// Months before the first anchor or after the last are not returned; callers verify coverage of
    /// their requested dates and report `missingNeighbourEvent` otherwise.
    public static func construct(_ inputs: Inputs) throws -> [ConstructedLunarMonth] {
        let n = inputs.conjunctionDates
        guard n.count >= 2 else { throw MonthConstructionFailure.missingNeighbourEvent(detail: "fewer than two conjunction dates") }
        for i in 1..<n.count {
            let len = n[i].days(since: n[i - 1])
            guard len >= 29, len <= 30 else {
                throw MonthConstructionFailure.invalidCadence(detail: "month from \(n[i - 1].label) to \(n[i].label) spans \(len) days")
            }
        }
        let solstices = inputs.winterSolsticeDates
        guard solstices.count >= 2 else { throw MonthConstructionFailure.missingNeighbourEvent(detail: "fewer than two winter-solstice anchors") }
        for i in 1..<solstices.count where solstices[i] <= solstices[i - 1] {
            throw MonthConstructionFailure.invalidCadence(detail: "winter solstice dates not increasing at \(solstices[i].label)")
        }

        // Month i is [n[i], n[i+1]); the month containing date d has the largest i with n[i] <= d.
        func monthIndex(containing date: GregorianDate) -> Int? {
            guard date >= n[0], date < n[n.count - 1] else { return nil }
            var lo = 0, hi = n.count - 1
            while hi - lo > 1 {
                let mid = (lo + hi) / 2
                if n[mid] <= date { lo = mid } else { hi = mid }
            }
            return lo
        }

        let terms = inputs.principalTermDates
        func principalTerms(in index: Int) -> [GregorianDate] {
            terms.filter { $0 >= n[index] && $0 < n[index + 1] }
        }

        var months: [ConstructedLunarMonth] = []
        var pendingNumbers: [(index: Int, number: Int, isLeap: Bool)] = []

        for s in 0..<(solstices.count - 1) {
            guard let startIndex = monthIndex(containing: solstices[s]), let endIndex = monthIndex(containing: solstices[s + 1]) else {
                throw MonthConstructionFailure.missingNeighbourEvent(detail: "a solstice at \(solstices[s].label) or \(solstices[s + 1].label) is not bracketed by conjunction dates")
            }
            let count = endIndex - startIndex
            guard count == 12 || count == 13 else {
                throw MonthConstructionFailure.invalidSpanStructure(detail: "solstice span from \(solstices[s].label) has \(count) months")
            }
            var leapIndex: Int? = nil
            if count == 13 {
                for i in (startIndex + 1)..<endIndex where principalTerms(in: i).isEmpty {
                    leapIndex = i
                    break
                }
                guard leapIndex != nil else {
                    throw MonthConstructionFailure.invalidSpanStructure(detail: "13-month span from \(solstices[s].label) has no termless month")
                }
            }
            var number = 11
            for i in startIndex..<endIndex {
                if i == leapIndex {
                    // Leap month repeats its predecessor's number.
                    pendingNumbers.append((i, number == 11 ? 11 : number, true))
                    // predecessor number is the last assigned; keep `number` unchanged for the next regular month
                    pendingNumbers[pendingNumbers.count - 1].number = pendingNumbers[pendingNumbers.count - 2].number
                    continue
                }
                pendingNumbers.append((i, number, false))
                number = number == 12 ? 1 : number + 1
            }
        }

        // Assign lunar years: a lunar year begins at regular month 1; months before the first regular
        // month 1 in the data belong to the previous lunar year.
        var currentYear: Int32? = nil
        // Determine the year of the first month: find the first regular month 1 after it.
        if let firstOne = pendingNumbers.first(where: { $0.number == 1 && !$0.isLeap }) {
            currentYear = n[firstOne.index].year - 1
        }
        guard var year = currentYear else {
            throw MonthConstructionFailure.missingNeighbourEvent(detail: "no regular month 1 inside the constructed spans")
        }
        for entry in pendingNumbers {
            if entry.number == 1 && !entry.isLeap {
                year = n[entry.index].year
            }
            let interval = try CivilDateInterval(startInclusive: n[entry.index], endExclusive: n[entry.index + 1])
            months.append(ConstructedLunarMonth(
                identity: LunarMonthID(lunarYearStartingGregorianYear: year, month: UInt8(entry.number), isLeapMonth: entry.isLeap),
                interval: interval,
                principalTermDates: principalTerms(in: entry.index)))
        }
        return months
    }

    public static func month(containing date: GregorianDate, in months: [ConstructedLunarMonth]) -> ConstructedLunarMonth? {
        months.first { $0.contains(date) }
    }

    public static func lunarDate(for date: GregorianDate, in months: [ConstructedLunarMonth]) -> (LunarDate, ConstructedLunarMonth)? {
        guard let m = month(containing: date, in: months) else { return nil }
        let day = Int(date.days(since: m.interval.startInclusive)) + 1
        guard let lunar = try? LunarDate(lunarYearStartingGregorianYear: Int(m.identity.lunarYearStartingGregorianYear), month: Int(m.identity.month), isLeapMonth: m.identity.isLeapMonth, day: day) else { return nil }
        return (lunar, m)
    }

    public enum InverseResult: Sendable, Hashable {
        case found(GregorianDate, ConstructedLunarMonth)
        case nonexistentMonth
        case impossibleDay(monthLength: Int)
    }

    public static func gregorianDate(for lunar: LunarDate, in months: [ConstructedLunarMonth]) -> InverseResult {
        let id = LunarMonthID(lunarYearStartingGregorianYear: lunar.lunarYearStartingGregorianYear, month: lunar.month, isLeapMonth: lunar.isLeapMonth)
        guard let m = months.first(where: { $0.identity == id }) else { return .nonexistentMonth }
        guard Int(lunar.day) <= m.length else { return .impossibleDay(monthLength: m.length) }
        guard let date = try? m.interval.startInclusive.adding(days: Int64(lunar.day) - 1) else { return .nonexistentMonth }
        return .found(date, m)
    }
}
