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

/// The live page follows the clock or stays on a held day. Browsing is local to each window.
struct PadDates {
    private(set) var today: String
    private(set) var advance: String?
    private(set) var heldDay: String?
    private(set) var preview: String?
    var automaticallyUpdatesDate: Bool { heldDay == nil }
    var live: String { heldDay ?? advance ?? today }
    var visible: String { preview ?? live }

    init(today: String, advance: String?, heldDay: String? = nil) {
        self.today = today
        refresh(today, persistedAdvance: advance, persistedHeldDay: heldDay)
    }

    mutating func refresh(_ localDay: String) {
        today = localDay
        if let advance, advance <= today || CivilDay.step(advance, 0) == nil { self.advance = nil }
    }

    mutating func refresh(_ localDay: String, persistedAdvance: String?, persistedHeldDay: String? = nil) {
        heldDay = persistedHeldDay
        advance = heldDay == nil ? persistedAdvance : nil
        refresh(localDay)
    }

    mutating func setAutomaticallyUpdatesDate(_ enabled: Bool) {
        guard enabled != automaticallyUpdatesDate else { return }
        if enabled {
            advance = heldDay
            heldDay = nil
            refresh(today)
        } else {
            heldDay = visible
            advance = nil
            preview = nil
        }
    }

    mutating func browse(_ label: String) {
        guard CivilDay.step(label, 0) != nil else { return }
        preview = label == live ? nil : label
    }

    mutating func returnToToday() {
        preview = nil
        advance = nil
        if heldDay != nil { heldDay = today }
    }

    mutating func tear() {
        guard let next = CivilDay.step(visible, 1) else { return }
        if heldDay != nil {
            heldDay = next
            preview = nil
        } else if preview != nil {
            browse(next)
        } else {
            advance = next
        }
    }
}
