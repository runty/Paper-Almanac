// Lunar date identity under the modern Hong Kong profile.
// The lunar year is identified by the Gregorian year in which its regular month 1 begins.

public struct LunarDate: Sendable, Hashable, Comparable {
    public let lunarYearStartingGregorianYear: Int32
    public let month: UInt8
    public let isLeapMonth: Bool
    public let day: UInt8

    /// Local component validation only. Whether the month exists in that year and whether
    /// the day fits its real length is decided against a prepared calendar.
    public init(lunarYearStartingGregorianYear: Int, month: Int, isLeapMonth: Bool, day: Int) throws {
        guard let y = Int32(exactly: lunarYearStartingGregorianYear), GregorianDate.yearDomain.contains(y) else {
            throw CoreValidationError.yearOutOfDomain(lunarYearStartingGregorianYear)
        }
        guard (1...12).contains(month), (1...30).contains(day) else {
            throw CoreValidationError.invalidLunarComponents(year: lunarYearStartingGregorianYear, month: month, day: day)
        }
        self.lunarYearStartingGregorianYear = y
        self.month = UInt8(month)
        self.isLeapMonth = isLeapMonth
        self.day = UInt8(day)
    }

    public static func < (lhs: LunarDate, rhs: LunarDate) -> Bool {
        if lhs.lunarYearStartingGregorianYear != rhs.lunarYearStartingGregorianYear {
            return lhs.lunarYearStartingGregorianYear < rhs.lunarYearStartingGregorianYear
        }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        // A leap month follows the regular month of the same number.
        if lhs.isLeapMonth != rhs.isLeapMonth { return !lhs.isLeapMonth }
        return lhs.day < rhs.day
    }
}

/// Identity of one lunar month within a lunar year.
public struct LunarMonthID: Sendable, Hashable {
    public let lunarYearStartingGregorianYear: Int32
    public let month: UInt8
    public let isLeapMonth: Bool

    public init(lunarYearStartingGregorianYear: Int32, month: UInt8, isLeapMonth: Bool) {
        self.lunarYearStartingGregorianYear = lunarYearStartingGregorianYear
        self.month = month
        self.isLeapMonth = isLeapMonth
    }
}
