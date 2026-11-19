// tung-shing-calendar-1901-2100-1 (research candidate c6c8c87, admitted 12e7e3d) with its context term days
// tung-shing-calendar-context-terms-1 (2a57de4, admitted ef1e2ef): the 1901–2100 lunar calendar as the research ships
// it, one table of months, term days, HKO differences and boundary-sensitive events, ported from `provider.py` and
// `context_terms.py`. Every fixed +08:00 date 1901-01-01 … 2100-12-31 is a model day on the frozen K=37 clock, never a
// historical civil clock. HKO's own dates are never substituted: a difference is reported beside the model's date.

import CryptoKit
import Foundation
import TungShingCore

public struct Calendar2100Provider: Sendable {
    public static let profile = "CAL-DE440S-REAL-HK8-K37-DAY-1901-2100-v1"
    public static let termNames = ["春分", "清明", "穀雨", "立夏", "小滿", "芒種", "夏至", "小暑", "大暑", "立秋", "處暑", "白露",
                                   "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至", "小寒", "大寒", "立春", "雨水", "驚蟄"]

    public struct Month: Sendable, Hashable {
        public let lunarYear: Int
        public let month: Int
        public let isLeap: Bool
        public let start: GregorianDate
        public let days: Int
    }

    /// A term day; context days (1899, 1900, 2101, 2102) are never displayed.
    public struct TermDay: Sendable, Hashable {
        public let date: GregorianDate
        public let index: Int
        public let isContext: Bool
    }

    public enum HKOComparison: Sendable, Hashable {
        case agrees
        case notPublished
        /// The Hong Kong Observatory table gives a different month start or term day; the model event that places
        /// the day and its conservative distance from midnight.
        case differs(field: String, modelEventID: String, marginSecondsFloor: Int, side: String)
    }

    /// A model event within the disclosure threshold (120 s) of an HK8 frozen-clock midnight that places this day.
    public struct BoundaryEvent: Sendable, Hashable {
        public let modelEventID: String
        public let kind: String
        public let marginSecondsFloor: Int
        public let side: String
    }

    public struct Day: Sendable, Hashable {
        public let date: GregorianDate
        public let lunarYear: Int
        public let month: Int
        public let isLeap: Bool
        public let day: Int
        public let monthLength: Int
        public let termIndex: Int?
        public let hko: HKOComparison
        public let boundary: [BoundaryEvent]
    }

    public enum Outcome: Sendable, Hashable {
        case known(Day)
        case invalidInput(field: String, reason: String)
        case missingInput(field: String)
        case unsupportedDomain(reason: String)
    }

    public enum LoadError: Error, Sendable, Hashable {
        case digest(String)
        case malformed(String)
    }

    /// This table's runtime profile, and the fixed civil offset its days are counted in.
    public let profileID: String
    public let fixedOffsetSeconds: Int
    /// The +08:00 table carries the Hong Kong Observatory comparison; the +07:00 and +09:00 tables
    /// (tung-shing-regional-lunar-calendars-1) don't.
    public let comparesWithHKO: Bool
    public let months: [Month]
    /// Every term day 1899–2102, contiguous, display and context merged (4,896).
    public let termDays: [TermDay]
    public let domain: CivilDateInterval
    private let startIDs: [Int64]
    private let index: [String: Int]
    private let displayTerms: [GregorianDate: Int]
    private let hko: [GregorianDate: HKOComparison]
    private let unpublished: Set<GregorianDate>
    private let sensitiveMonths: [GregorianDate: BoundaryEvent]
    private let sensitiveTerms: [GregorianDate: [BoundaryEvent]]

    /// Reads the runtime table and the context term days, refusing either when its digest, schema, profile or
    /// structure disagrees (`provider.py` and `context_terms.py`).
    public init(runtime: Data, context: Data, runtimeSHA256: String, contextSHA256: String) throws(LoadError) {
        func hex(_ d: Data) -> String { SHA256.hash(data: d).map { String(format: "%02x", $0) }.joined() }
        guard hex(runtime) == runtimeSHA256 else { throw .digest("runtime") }
        guard hex(context) == contextSHA256 else { throw .digest("context") }
        guard let rt = (try? JSONSerialization.jsonObject(with: runtime)) as? [String: Any],
              let cx = (try? JSONSerialization.jsonObject(with: context)) as? [String: Any] else { throw .malformed("json") }
        guard rt["schema"] as? String == "lunar-calendar-runtime-1", rt["runtimeProfile"] as? String == Self.profile else { throw .malformed("runtime schema") }
        guard cx["calendarProfile"] as? String == Self.profile else { throw .malformed("context profile") }
        try self.init(table: rt, contextRows: cx["rows"] as? [Any] ?? [], profile: Self.profile, offset: 28_800, comparesWithHKO: true)
    }

    /// Reads a fixed-offset table (`regional-lunar-calendars-1` provider.py): its own profile and offset, its context
    /// term days inside the file, and no HKO comparison.
    public init(offsetRuntime: Data, sha256: String) throws(LoadError) {
        guard SHA256.hash(data: offsetRuntime).map({ String(format: "%02x", $0) }).joined() == sha256 else { throw .digest("runtime") }
        guard let rt = (try? JSONSerialization.jsonObject(with: offsetRuntime)) as? [String: Any],
              rt["schema"] as? String == "lunar-calendar-offset-runtime-1", let profile = rt["runtimeProfile"] as? String,
              let offset = (rt["fixedOffsetSeconds"] as? NSNumber)?.intValue else { throw .malformed("runtime schema") }
        try self.init(table: rt, contextRows: rt["contextTerms"] as? [Any] ?? [], profile: profile, offset: offset, comparesWithHKO: false)
    }

    private init(table rt: [String: Any], contextRows: [Any], profile: String, offset: Int, comparesWithHKO: Bool) throws(LoadError) {
        profileID = profile
        fixedOffsetSeconds = offset
        self.comparesWithHKO = comparesWithHKO
        func date(_ v: Any?) throws(LoadError) -> GregorianDate {
            guard let s = v as? String, let d = try? GregorianDate(label: s) else { throw .malformed("date \(String(describing: v))") }
            return d
        }
        func int(_ v: Any?) throws(LoadError) -> Int {
            guard let n = v as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { throw .malformed("integer") }
            return n.intValue
        }
        guard let domain = rt["domain"] as? [String: Any] else { throw .malformed("domain") }
        let start = try date(domain["startInclusive"]), end = try date(domain["endExclusive"])
        guard let interval = try? CivilDateInterval(startInclusive: start, endExclusive: end) else { throw .malformed("domain") }
        self.domain = interval

        var months: [Month] = []
        for case let row as [Any] in rt["months"] as? [Any] ?? [] {
            guard row.count == 5, let leap = row[2] as? NSNumber else { throw .malformed("month row") }
            months.append(Month(lunarYear: try int(row[0]), month: try int(row[1]), isLeap: leap.intValue != 0, start: try date(row[3]), days: try int(row[4])))
        }
        guard let first = months.first, let last = months.last else { throw .malformed("months") }
        for (a, b) in zip(months, months.dropFirst()) {
            guard (29...30).contains(a.days), (try? a.start.adding(days: Int64(a.days))) == b.start else { throw .malformed("Corrupt month table") }
        }
        guard (29...30).contains(last.days), first.start <= start, let lastEnd = try? last.start.adding(days: Int64(last.days)), lastEnd >= end else {
            throw .malformed("Month table does not cover the domain")
        }
        self.months = months
        startIDs = months.map(\.start.dayID.value)
        var index: [String: Int] = [:]
        for (i, m) in months.enumerated() { index["\(m.lunarYear)-\(m.month)-\(m.isLeap)"] = i }
        self.index = index

        var terms: [TermDay] = [], display: [GregorianDate: Int] = [:]
        for case let row as [Any] in rt["terms"] as? [Any] ?? [] {
            guard row.count == 2 else { throw .malformed("term row") }
            let t = TermDay(date: try date(row[0]), index: try int(row[1]), isContext: false)
            terms.append(t)
            display[t.date] = t.index
        }
        for case let row as [Any] in contextRows {
            guard row.count >= 2 else { throw .malformed("context row") }
            terms.append(TermDay(date: try date(row[0]), index: try int(row[1]), isContext: true))
        }
        terms.sort { ($0.date, $0.index) < ($1.date, $1.index) }
        for (a, b) in zip(terms, terms.dropFirst()) {
            let gap = b.date.days(since: a.date)
            guard b.index == (a.index + 1) % 24, (13...17).contains(gap) else { throw .malformed("Term sequence is not contiguous at \(b.date.label)") }
        }
        termDays = terms
        displayTerms = display

        var hko: [GregorianDate: HKOComparison] = [:]
        for case let row as [Any] in rt["hkoDifferences"] as? [Any] ?? [] {
            guard row.count == 5, let field = row[1] as? String, let event = row[2] as? String, let side = row[4] as? String else { throw .malformed("hko row") }
            hko[try date(row[0])] = .differs(field: field, modelEventID: event, marginSecondsFloor: try int(row[3]), side: side)
        }
        self.hko = hko
        var unpublished = Set<GregorianDate>()
        for d in rt["hkoUnpublishedDates"] as? [Any] ?? [] { unpublished.insert(try date(d)) }
        self.unpublished = unpublished
        var sMonths: [GregorianDate: BoundaryEvent] = [:], sTerms: [GregorianDate: [BoundaryEvent]] = [:]
        for case let row as [Any] in rt["boundarySensitiveEvents"] as? [Any] ?? [] {
            guard row.count == 5, let kind = row[1] as? String, let event = row[2] as? String, let side = row[4] as? String else { throw .malformed("boundary row") }
            let day = try date(row[0])
            let note = BoundaryEvent(modelEventID: event, kind: kind, marginSecondsFloor: try int(row[3]), side: side)
            if kind == "conjunction" {
                sMonths[day] = note
            } else {
                guard let other = try? day.adding(days: side == "before-midnight" ? 1 : -1) else { throw .malformed("boundary day") }
                for k in [day, other] { sTerms[k, default: []].append(note) }
            }
        }
        sensitiveMonths = sMonths
        sensitiveTerms = sTerms
    }

    // MARK: Calls

    func checked(_ profile: String?) -> Outcome? {
        guard let profile else { return .missingInput(field: "profile") }
        guard profile == profileID else { return .invalidInput(field: "profile", reason: "Exact runtime profile required") }
        return nil
    }

    /// `Provider.lunar`: the lunar facts of a Gregorian date.
    public func lunar(year: Int, month: Int, day: Int, profile: String?) -> Outcome {
        if let bad = checked(profile) { return bad }
        guard let d = try? GregorianDate(year: year, month: month, day: day) else { return .invalidInput(field: "date", reason: "No such Gregorian date") }
        guard domain.contains(d) else { return .unsupportedDomain(reason: "Gregorian dates 1901-01-01 … 2100-12-31 only") }
        return .known(facts(d))
    }

    /// `Provider.gregorian`: the date of a lunar date, which needs the leap flag.
    public func gregorian(lunarYear: Int, month: Int, isLeap: Bool?, day: Int, profile: String?) -> Outcome {
        if let bad = checked(profile) { return bad }
        guard let isLeap else { return .missingInput(field: "isLeap") }
        guard let i = index["\(lunarYear)-\(month)-\(isLeap)"], (1...months[i].days).contains(day) else {
            if !(1900...2100).contains(lunarYear) { return .unsupportedDomain(reason: "Lunar years inside the 1901–2100 Gregorian domain only") }
            return .invalidInput(field: "date", reason: "No such lunar date")
        }
        guard let d = try? months[i].start.adding(days: Int64(day - 1)), domain.contains(d) else { return .unsupportedDomain(reason: "Result outside 1901–2100") }
        return .known(facts(d))
    }

    /// The month containing a date of the table, if any.
    public func month(containing date: GregorianDate) -> Month? {
        let id = date.dayID.value
        var lo = 0, hi = startIDs.count
        while lo < hi { let mid = (lo + hi) / 2; if startIDs[mid] <= id { lo = mid + 1 } else { hi = mid } }
        guard lo > 0 else { return nil }
        let m = months[lo - 1]
        return date.days(since: m.start) < Int64(m.days) ? m : nil
    }

    /// The day's facts; the date must lie in the domain.
    public func facts(_ d: GregorianDate) -> Day {
        let m = month(containing: d)!
        let next = try! m.start.adding(days: Int64(m.days))
        var bounds = [m.start, next].compactMap { sensitiveMonths[$0] }
        bounds += sensitiveTerms[d] ?? []
        let comparison: HKOComparison = unpublished.contains(d) ? .notPublished : (hko[d] ?? .agrees)
        return Day(date: d, lunarYear: m.lunarYear, month: m.month, isLeap: m.isLeap, day: Int(d.days(since: m.start)) + 1, monthLength: m.days,
                   termIndex: displayTerms[d], hko: comparison, boundary: bounds)
    }

    // MARK: Term days (`context_terms.py`)

    public enum TermsOutcome: Sendable, Hashable {
        case known([TermDay])
        case unsupportedDomain(reason: String)
    }

    /// `TermDays.between`: term days with start ≤ date < end, refusing requests past 1899–2102.
    public func termDays(from start: String, to end: String) -> TermsOutcome {
        guard "1899-01-01" <= start, start <= end, end <= "2102-12-31", let s = try? GregorianDate(label: start), let e = try? GregorianDate(label: end) else {
            return .unsupportedDomain(reason: "Term days 1899-01-01 … 2102-12-30 only")
        }
        return .known(termDays.filter { s <= $0.date && $0.date < e })
    }

    /// `TermDays.year`: the 24 term days of a Gregorian year, 小寒 first.
    public func termDays(year: Int) -> TermsOutcome {
        guard (1899...2102).contains(year) else { return .unsupportedDomain(reason: "Gregorian years 1899–2102 only") }
        return .known(termDays.filter { Int($0.date.year) == year })
    }
}
