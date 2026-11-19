// The evaluator uses one civil day and the solar terms in its surrounding window.

import TungShingCore

/// A solar term on a civil date, using the E1 index (0 = 春分 … 21 = 立春 … 23 = 惊蛰).
public struct SolarTermDate: Sendable, Hashable, Comparable {
    public let indexFromMarchEquinox: UInt8
    public let date: GregorianDate

    public init(indexFromMarchEquinox: Int, date: GregorianDate) throws {
        guard (0...23).contains(indexFromMarchEquinox) else { throw CoreValidationError.invalidTermIndex(indexFromMarchEquinox) }
        self.indexFromMarchEquinox = UInt8(indexFromMarchEquinox)
        self.date = date
    }

    /// Upstream `SOLAR_TERMS_NAME_LIST` index (0 = 小寒): `(e1 + 5) % 24`.
    public var upstreamIndex: Int { (Int(indexFromMarchEquinox) + 5) % 24 }
    /// Upstream term name.
    public var upstreamName: String { UpstreamTables.solarTermNames[upstreamIndex] }
    /// E1 index from an upstream index: `(k + 19) % 24`.
    public static func e1Index(fromUpstreamIndex k: Int) -> Int { (k + 19) % 24 }

    /// 立春/立夏/立秋/立冬 (E1 indices 21, 3, 9, 15).
    public var isSeasonStart: Bool { [21, 3, 9, 15].contains(Int(indexFromMarchEquinox)) }
    /// 春分/夏至/秋分/冬至 (E1 indices 0, 6, 12, 18).
    public var isEquinoxOrSolstice: Bool { [0, 6, 12, 18].contains(Int(indexFromMarchEquinox)) }

    public static func < (lhs: SolarTermDate, rhs: SolarTermDate) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        return lhs.indexFromMarchEquinox < rhs.indexFromMarchEquinox
    }
}

/// Typed reasons a context cannot be built.
public enum AlmanacContextError: Error, Sendable, Hashable {
    case invalidEvaluationHour(Int)
    case invalidLunarMonthLength(Int)
    /// The lunar year must be the Gregorian year or the one before it.
    case lunarYearInconsistent(lunarYear: Int, gregorianYear: Int)
    case solarTermsNotSorted(position: Int)
    case duplicateSolarTermDate(GregorianDate)
    /// Consecutive terms must have consecutive indices modulo 24.
    case solarTermsNotContiguous(position: Int)
    /// The window `[date − required, date + required]` is not witnessed by the supplied terms.
    case insufficientSolarTermWindow(requiredDays: Int64, earliest: GregorianDate?, latest: GregorianDate?)
    case dateArithmetic
}

/// Calendar facts for one civil date, ready for the almanac evaluator.
public struct AlmanacDayContext: Sendable, Hashable {
    /// Required coverage on each side of the date. The port itself reads at most 16 days back
    /// (latest term on or before the date) and 18 days ahead (土王用事, next term, 四离/四绝);
    /// 60 is the contract margin so one E1 dependency closure serves a whole month.
    public static let requiredWindowDays: Int64 = 60

    public let gregorian: GregorianDate
    public let lunar: LunarDate
    /// 29 or 30.
    public let lunarMonthLength: UInt8
    /// 0…23.
    public let evaluationHour: UInt8
    /// Sorted, contiguous solar terms witnessing `[gregorian − 60, gregorian + 60]`.
    public let solarTerms: [SolarTermDate]

    /// Validating initializer.
    public init(gregorian: GregorianDate, lunar: LunarDate, lunarMonthLength: Int, evaluationHour: Int,
                solarTerms: [SolarTermDate]) throws(AlmanacContextError) {
        guard (0...23).contains(evaluationHour) else { throw .invalidEvaluationHour(evaluationHour) }
        guard lunarMonthLength == 29 || lunarMonthLength == 30 else { throw .invalidLunarMonthLength(lunarMonthLength) }
        let ly = Int(lunar.lunarYearStartingGregorianYear), gy = Int(gregorian.year)
        guard ly == gy || ly == gy - 1 else { throw .lunarYearInconsistent(lunarYear: ly, gregorianYear: gy) }
        try AlmanacDayContext.validateTerms(solarTerms)
        guard let lower = try? gregorian.adding(days: -AlmanacDayContext.requiredWindowDays),
              let upper = try? gregorian.adding(days: AlmanacDayContext.requiredWindowDays) else {
            throw .dateArithmetic
        }
        guard let first = solarTerms.first, let last = solarTerms.last, first.date <= lower, last.date >= upper else {
            throw .insufficientSolarTermWindow(requiredDays: AlmanacDayContext.requiredWindowDays,
                                               earliest: solarTerms.first?.date, latest: solarTerms.last?.date)
        }
        self.gregorian = gregorian
        self.lunar = lunar
        self.lunarMonthLength = UInt8(lunarMonthLength)
        self.evaluationHour = UInt8(evaluationHour)
        self.solarTerms = solarTerms
    }

    /// Test-only construction without the window witness. Used by the differential tests for
    /// the first and last rows of the upstream table domain, where upstream itself only reads
    /// the current year's table. Term ordering and contiguity are still validated.
    init(uncheckedWindow gregorian: GregorianDate, lunar: LunarDate, lunarMonthLength: Int, evaluationHour: Int,
         solarTerms: [SolarTermDate]) throws(AlmanacContextError) {
        guard (0...23).contains(evaluationHour) else { throw .invalidEvaluationHour(evaluationHour) }
        guard lunarMonthLength == 29 || lunarMonthLength == 30 else { throw .invalidLunarMonthLength(lunarMonthLength) }
        let ly = Int(lunar.lunarYearStartingGregorianYear), gy = Int(gregorian.year)
        guard ly == gy || ly == gy - 1 else { throw .lunarYearInconsistent(lunarYear: ly, gregorianYear: gy) }
        try AlmanacDayContext.validateTerms(solarTerms)
        self.gregorian = gregorian
        self.lunar = lunar
        self.lunarMonthLength = UInt8(lunarMonthLength)
        self.evaluationHour = UInt8(evaluationHour)
        self.solarTerms = solarTerms
    }

    private static func validateTerms(_ terms: [SolarTermDate]) throws(AlmanacContextError) {
        var i = 1
        while i < terms.count {
            let prev = terms[i - 1], cur = terms[i]
            if cur.date == prev.date { throw .duplicateSolarTermDate(cur.date) }
            if cur.date < prev.date { throw .solarTermsNotSorted(position: i) }
            if Int(cur.indexFromMarchEquinox) != (Int(prev.indexFromMarchEquinox) + 1) % 24 {
                throw .solarTermsNotContiguous(position: i)
            }
            i += 1
        }
    }

    // MARK: Derived term facts used by the evaluator

    /// The term falling on the date, if any.
    public var termOnDate: SolarTermDate? { solarTerms.first { $0.date == gregorian } }

    /// Latest term on or before the date.
    public var latestTermOnOrBefore: SolarTermDate? { solarTerms.last { $0.date <= gregorian } }

    /// First term strictly after the date.
    public var nextTermAfter: SolarTermDate? { solarTerms.first { $0.date > gregorian } }

    /// The term falling on the following civil date, if any.
    public var termOnTomorrow: SolarTermDate? {
        guard let tomorrow = try? gregorian.adding(days: 1) else { return nil }
        return solarTerms.first { $0.date == tomorrow }
    }
}
