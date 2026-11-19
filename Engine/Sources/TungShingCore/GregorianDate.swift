// Proleptic Gregorian civil-date labels and exact integer day arithmetic.
// A GregorianDate is a label, never a Foundation.Date; see docs/design/PHASE_1_ENGINE.md §2.

/// Integer day count. Day 0 is 1970-01-01 in the proleptic Gregorian calendar.
public struct CivilDayID: Sendable, Hashable, Comparable {
    public let value: Int64
    public init(_ value: Int64) { self.value = value }
    public static func < (lhs: CivilDayID, rhs: CivilDayID) -> Bool { lhs.value < rhs.value }
}

public struct GregorianDate: Sendable, Hashable, Comparable {
    /// Supported year domain. Astronomical year 0 is representable so halos can precede year 1.
    public static let yearDomain: ClosedRange<Int32> = 0...9999

    public let year: Int32
    public let month: UInt8
    public let day: UInt8

    /// Checked construction: rejects impossible days and years outside the domain.
    public init(year: Int, month: Int, day: Int) throws {
        guard let y = Int32(exactly: year), GregorianDate.yearDomain.contains(y) else {
            throw CoreValidationError.yearOutOfDomain(year)
        }
        guard (1...12).contains(month), day >= 1, day <= GregorianDate.daysInMonth(year: y, month: UInt8(month)) else {
            throw CoreValidationError.invalidGregorianDate(year: year, month: month, day: day)
        }
        self.year = y
        self.month = UInt8(month)
        self.day = UInt8(day)
    }

    public static func isLeapYear(_ year: Int32) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    public static func daysInMonth(year: Int32, month: UInt8) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11: return 30
        case 2: return isLeapYear(year) ? 29 : 28
        default: return 0
        }
    }

    /// Days since 1970-01-01 (Howard Hinnant's days_from_civil). Exact for the whole domain.
    public var dayID: CivilDayID {
        let y = Int64(year) - (month <= 2 ? 1 : 0)
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let m = Int64(month)
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + Int64(day) - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return CivilDayID(era * 146097 + doe - 719468)
    }

    /// Inverse of `dayID` (civil_from_days). Throws if the result leaves the year domain.
    public init(dayID: CivilDayID) throws {
        let z = dayID.value + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let doe = z - era * 146097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        let year = y + (m <= 2 ? 1 : 0)
        guard let y32 = Int32(exactly: year), GregorianDate.yearDomain.contains(y32) else {
            throw CoreValidationError.yearOutOfDomain(Int(clamping: year))
        }
        self.year = y32
        self.month = UInt8(m)
        self.day = UInt8(d)
    }

    /// Weekday with Sunday = 0 … Saturday = 6.
    public var weekdaySunday0: Int {
        let r = (dayID.value + 4) % 7   // 1970-01-01 was a Thursday (4)
        return Int(r < 0 ? r + 7 : r)
    }

    public var weekday: Weekday { Weekday(rawValue: weekdaySunday0) ?? .sunday }

    public func adding(days: Int64) throws -> GregorianDate {
        let (sum, overflow) = dayID.value.addingReportingOverflow(days)
        guard !overflow else { throw CoreValidationError.arithmeticOverflow }
        return try GregorianDate(dayID: CivilDayID(sum))
    }

    /// Signed number of days from `other` to `self`.
    /// Parses the canonical `YYYY-MM-DD` label produced by `label`.
    public init(label: String) throws {
        let parts = label.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else {
            throw CoreValidationError.invalidGregorianDate(year: 0, month: 0, day: 0)
        }
        try self.init(year: y, month: m, day: d)
    }

    public func days(since other: GregorianDate) -> Int64 {
        dayID.value - other.dayID.value
    }

    public static func < (lhs: GregorianDate, rhs: GregorianDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// ISO-style label used in evidence and diagnostics; never a calculation input.
    public var label: String {
        func pad(_ v: Int, _ width: Int) -> String {
            let s = String(v)
            return String(repeating: "0", count: max(0, width - s.count)) + s
        }
        return "\(pad(Int(year), 4))-\(pad(Int(month), 2))-\(pad(Int(day), 2))"
    }
}

/// A day of the week of a civil date, Sunday first. A user's constraint on days, never a calculation input.
public enum Weekday: Int, Sendable, Hashable, CaseIterable, Comparable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct GregorianYearMonth: Sendable, Hashable, Comparable {
    public let year: Int32
    public let month: UInt8

    public init(year: Int, month: Int) throws {
        guard let y = Int32(exactly: year), GregorianDate.yearDomain.contains(y) else {
            throw CoreValidationError.yearOutOfDomain(year)
        }
        guard (1...12).contains(month) else {
            throw CoreValidationError.invalidGregorianDate(year: year, month: month, day: 1)
        }
        self.year = y
        self.month = UInt8(month)
    }

    public var daysInMonth: Int { GregorianDate.daysInMonth(year: year, month: month) }

    public var firstDay: GregorianDate {
        // Cannot fail: year and month were validated.
        try! GregorianDate(year: Int(year), month: Int(month), day: 1)
    }

    public var lastDay: GregorianDate {
        try! GregorianDate(year: Int(year), month: Int(month), day: daysInMonth)
    }

    /// Half-open interval covering exactly this month.
    public var interval: CivilDateInterval {
        let start = firstDay
        let end = try! start.adding(days: Int64(daysInMonth))
        return try! CivilDateInterval(startInclusive: start, endExclusive: end)
    }

    public static func < (lhs: GregorianYearMonth, rhs: GregorianYearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

/// `[startInclusive, endExclusive)` in civil dates. Never empty.
public struct CivilDateInterval: Sendable, Hashable {
    public let startInclusive: GregorianDate
    public let endExclusive: GregorianDate

    public init(startInclusive: GregorianDate, endExclusive: GregorianDate) throws {
        guard startInclusive < endExclusive else { throw CoreValidationError.invalidInterval }
        self.startInclusive = startInclusive
        self.endExclusive = endExclusive
    }

    public func contains(_ date: GregorianDate) -> Bool {
        startInclusive <= date && date < endExclusive
    }

    public var dayCount: Int64 { endExclusive.days(since: startInclusive) }

    /// All dates in ascending order.
    public var dates: [GregorianDate] {
        var out: [GregorianDate] = []
        out.reserveCapacity(Int(dayCount))
        var cursor = startInclusive
        while cursor < endExclusive {
            out.append(cursor)
            cursor = try! cursor.adding(days: 1)
        }
        return out
    }
}

/// Sorted, disjoint, non-adjacent-coalesced half-open intervals. Empty means no accepted dates.
public struct AcceptedDateDomain: Sendable, Hashable {
    public let intervals: [CivilDateInterval]

    public init(intervals: [CivilDateInterval]) throws {
        let sorted = intervals.sorted { $0.startInclusive < $1.startInclusive }
        var merged: [CivilDateInterval] = []
        for interval in sorted {
            if let last = merged.last {
                guard interval.startInclusive >= last.endExclusive else { throw CoreValidationError.invalidInterval }
                if interval.startInclusive == last.endExclusive {
                    merged[merged.count - 1] = try CivilDateInterval(startInclusive: last.startInclusive, endExclusive: interval.endExclusive)
                    continue
                }
            }
            merged.append(interval)
        }
        self.intervals = merged
    }

    public static let empty = try! AcceptedDateDomain(intervals: [])

    public func contains(_ date: GregorianDate) -> Bool {
        intervals.contains { $0.contains(date) }
    }

    public func contains(_ interval: CivilDateInterval) -> Bool {
        intervals.contains { $0.startInclusive <= interval.startInclusive && interval.endExclusive <= $0.endExclusive }
    }
}
