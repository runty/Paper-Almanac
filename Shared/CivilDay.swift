import Foundation
import TungShingCore

enum CivilDay {
    static let range = "1901-01-01"..."2100-12-31"

    static func calendar(zone: TimeZone = .autoupdatingCurrent) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    static func label(_ instant: Date = .now, zone: TimeZone = .autoupdatingCurrent) -> String {
        let c = calendar(zone: zone).dateComponents([.year, .month, .day], from: instant)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    static func step(_ label: String, _ offset: Int) -> String? {
        guard let next = try? GregorianDate(label: label).adding(days: Int64(offset)).label,
              range.contains(next) else { return nil }
        return next
    }

    /// Fraction of the year's underlying sheets, excluding the visible top sheet.
    static func remainingPaper(on label: String) -> Double {
        guard let day = try? GregorianDate(label: label),
              let last = try? GregorianDate(year: Int(day.year), month: 12, day: 31) else { return 0 }
        return Double(last.days(since: day)) / (GregorianDate.isLeapYear(day.year) ? 365 : 364)
    }

    static func nextMidnight(after instant: Date, zone: TimeZone = .autoupdatingCurrent) -> Date {
        calendar(zone: zone).dateInterval(of: .day, for: instant)!.end
    }
}

/// The persisted state is just an intentional advance. A preview belongs to this session.
struct PadDates {
    private(set) var today: String
    private(set) var advance: String?
    private(set) var preview: String?
    var live: String { advance ?? today }
    var visible: String { preview ?? live }
    init(today: String, advance: String?) {
        self.today = today
        self.advance = advance
        refresh(today)
    }
    mutating func refresh(_ localDay: String) {
        today = localDay
        if let advance, advance <= today || !CivilDay.range.contains(advance) { self.advance = nil }
    }
    mutating func refresh(_ localDay: String, persistedAdvance: String?) {
        advance = persistedAdvance
        refresh(localDay)
    }
    mutating func browse(_ label: String) {
        guard CivilDay.range.contains(label), (try? GregorianDate(label: label)) != nil else { return }
        preview = label == live ? nil : label
    }
    mutating func returnToToday() { preview = nil; advance = nil }
    mutating func tear() {
        guard let next = CivilDay.step(visible, 1) else { return }
        if preview != nil { browse(next) } else { advance = next }
    }
}
