// tung-shing-regional-holidays-jp-1 (research candidate 81f5d30, admitted e3eb3f8): Japanese national holidays, substitute
// holidays (振替休日), citizens' holidays (国民の休日) and special acts, 1955–2027, from the Cabinet Office tables, ported from
// the research's provider.py. Names are shown verbatim; later years are refused until published, never inferred.

import CryptoKit
import Foundation

public struct JapanHolidays: Sendable {
    public static let runtimeProfile = "OFFICIAL-HOLIDAYS-JP-1955-2027-v1"

    public enum LoadError: Error, Equatable {
        case digest
        case malformed(String)
    }

    public struct Holiday: Hashable, Sendable {
        public let name: String
        /// national-holiday, substitute-holiday, citizens-holiday or special-act.
        public let kind: String
    }

    public struct Day: Hashable, Sendable {
        public let profile: String
        public let date: String
        public let officialDayOff: Bool
        public let holiday: Holiday?
    }

    public struct DatedHoliday: Hashable, Sendable {
        public let date: String
        public let holiday: Holiday
    }

    public struct Year: Hashable, Sendable {
        public let profile: String
        public let year: Int
        public let holidays: [DatedHoliday]
    }

    public enum Result<Value: Hashable & Sendable>: Hashable, Sendable {
        case known(Value)
        case invalidInput(field: String, reason: String)
        case missingInput(field: String)
        case unsupportedDomain(reason: String)
    }

    public let profile: String
    public let years: ClosedRange<Int>
    public let attribution: String
    let rows: [String: Holiday]

    public init(data: Data, sha256: String) throws(LoadError) {
        guard SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == sha256 else { throw .digest }
        guard let d = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any], d["schema"] as? String == "official-holidays-runtime-1",
              d["jurisdiction"] as? String == "JP", let profile = d["runtimeProfile"] as? String, let domain = d["domain"] as? [String: Any],
              let first = (domain["firstYear"] as? NSNumber)?.intValue, let last = (domain["lastYear"] as? NSNumber)?.intValue,
              let attribution = d["attribution"] as? String, let raw = d["rows"] as? [[Any]] else { throw .malformed("Unsupported runtime table") }
        var rows: [String: Holiday] = [:]
        for r in raw {
            guard r.count >= 3, let date = r[0] as? String, let name = r[1] as? String, let kind = r[2] as? String else { throw .malformed("row") }
            guard rows[date] == nil else { throw .malformed("Duplicate dates") }
            rows[date] = Holiday(name: name, kind: kind)
        }
        self.profile = profile
        self.years = first...last
        self.attribution = attribution
        self.rows = rows
    }

    func checked<V>(_ profile: String?) -> Result<V>? {
        guard let profile else { return .missingInput(field: "profile") }
        guard profile == self.profile else { return .invalidInput(field: "profile", reason: "Exact runtime profile required") }
        return nil
    }

    var unpublished: String { "Japanese national holidays \(years.lowerBound)–\(years.upperBound) only; later years are not yet published" }

    /// `Provider.day`.
    public func day(year: Int, month: Int, day: Int, profile: String?) -> Result<Day> {
        if let bad: Result<Day> = checked(profile) { return bad }
        guard (1...12).contains(month), day >= 1, day <= Self.daysIn(year, month) else { return .invalidInput(field: "date", reason: "No such Gregorian date") }
        guard years.contains(year) else { return .unsupportedDomain(reason: unpublished) }
        let label = String(format: "%04d-%02d-%02d", year, month, day)
        let h = rows[label]
        return .known(Day(profile: profile!, date: label, officialDayOff: h != nil, holiday: h))
    }

    /// `Provider.year`.
    public func year(_ year: Int, profile: String?) -> Result<Year> {
        if let bad: Result<Year> = checked(profile) { return bad }
        guard years.contains(year) else { return .unsupportedDomain(reason: unpublished) }
        let prefix = String(format: "%04d", year)
        return .known(Year(profile: profile!, year: year, holidays: rows.filter { $0.key.hasPrefix(prefix) }.sorted { $0.key < $1.key }.map { DatedHoliday(date: $0.key, holiday: $0.value) }))
    }

    static func daysIn(_ y: Int, _ m: Int) -> Int {
        switch m {
        case 2: (y % 4 == 0 && y % 100 != 0) || y % 400 == 0 ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }
}

/// The bundled Japanese table (byte-identical copy, refused unless it has its pinned digest).
public enum RegionalHolidaysJP1Assets {
    public static let runtimeSHA256 = "147a8cd38f097c8c5319fb4342f57e143bf9cbda7df5d4090295f8d896ddfe7b"

    public static let holidays: JapanHolidays? = {
        guard let url = Bundle.module.url(forResource: "JP_RUNTIME_DATA", withExtension: "json"), let data = try? Data(contentsOf: url) else { return nil }
        return try? JapanHolidays(data: data, sha256: runtimeSHA256)
    }()
}
