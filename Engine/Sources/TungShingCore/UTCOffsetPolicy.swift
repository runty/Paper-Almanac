// TT → UTC offset segments shared by every civil projection the app performs.
//
// TT = TAI + 32.184 s; UTC = TAI − (TAI − UTC). From 1972 until the end of the bundled IERS table (2027-01-23,
// as packed in Skyfield 1.55) TAI − UTC steps through the leap-second table. The research calendar review
// (`docs/handoff/calendar-pack/REVIEW_AND_GAP_CLOSURE.md` §2, research commit 3f3c5ef) adds the two sources
// that fix the offset after that: JPL/NAIF's July 2026 announcement of no leap second at the end of December
// 2026 (leap-second kernel current until at least July 2027; last offset TAI − UTC = 37 s), and CGPM 2026
// Resolution 5, under which UTC is continuous from 2027-05-20. Hence TAI − UTC = 37 s from 2017-01-01 on, with
// no further step. Before 1972 there is no UTC; that era uses UT1 from the S15.2020 ΔT spline (`HistoricalUT1`,
// research `ut1-historical-clock`, adopted for Ba Zi term clocks under decision F of RESEARCH_ADOPTION_2026-10-26).

public enum UTCOffsetPolicy {
    public enum Segment: String, Sendable, Hashable, CaseIterable {
        /// Before 1972-01-01 UTC: UT1-based civil time, ΔT from the S15.2020 spline (`HistoricalUT1`).
        case beforeUTC = "pre-utc-ut1-s15"
        /// 1972-01-01 ≤ t < 2027-01-23 UTC: the IERS leap-second table.
        case leapTable = "utc-leap-table"
        /// 2027-01-23 ≤ t < 2027-05-20 UTC: TAI − UTC held at 37 s (JPL/NAIF: no leap second through July 2027).
        case heldOffset = "held-offset-tai37-2027"
        /// From 2027-05-20 UTC: continuous UTC, TAI − UTC = K = 37 s (CGPM 2026 Resolution 5).
        case continuousUTC = "continuous-utc-k37"
    }

    /// TAI − UTC after each step (IERS Bulletin C; the table bundled in Skyfield 1.55 that the pack's projection
    /// used). TAI − UTC = 10 s from 1972-01-01 until the first step.
    public static let leapSecondSteps: [(utcDate: GregorianDate, taiMinusUTC: Int)] = [
        (d(1972, 7, 1), 11), (d(1973, 1, 1), 12), (d(1974, 1, 1), 13), (d(1975, 1, 1), 14), (d(1976, 1, 1), 15),
        (d(1977, 1, 1), 16), (d(1978, 1, 1), 17), (d(1979, 1, 1), 18), (d(1980, 1, 1), 19), (d(1981, 7, 1), 20),
        (d(1982, 7, 1), 21), (d(1983, 7, 1), 22), (d(1985, 7, 1), 23), (d(1988, 1, 1), 24), (d(1990, 1, 1), 25),
        (d(1991, 1, 1), 26), (d(1992, 7, 1), 27), (d(1993, 7, 1), 28), (d(1994, 7, 1), 29), (d(1996, 1, 1), 30),
        (d(1997, 7, 1), 31), (d(1999, 1, 1), 32), (d(2006, 1, 1), 33), (d(2009, 1, 1), 34), (d(2012, 7, 1), 35),
        (d(2015, 7, 1), 36), (d(2017, 1, 1), 37),
    ]
    public static let baseTaiMinusUTC = 10
    /// K, the TAI − UTC offset that continuous UTC keeps.
    public static let continuousTaiMinusUTC = 37

    public static let utcStartTT: TTInstant = ttOfUTCMidnight(d(1972, 1, 1), taiMinusUTC: 10)
    public static let leapTableEndTT: TTInstant = ttOfUTCMidnight(d(2027, 1, 23), taiMinusUTC: 37)
    public static let continuousUTCStartTT: TTInstant = ttOfUTCMidnight(d(2027, 5, 20), taiMinusUTC: 37)

    public static let ttMinusTAINanoseconds: Int64 = 32_184_000_000
    public static let nanosecondsPerSecond: Int64 = 1_000_000_000

    private static func d(_ y: Int, _ m: Int, _ day: Int) -> GregorianDate { try! GregorianDate(year: y, month: m, day: day) }

    /// Julian Day Number of a civil date (the JD at its noon; J(2000-01-01) = 2451545).
    public static func julianDayNumber(_ date: GregorianDate) -> Int64 { 2_451_545 + date.days(since: d(2000, 1, 1)) }
    /// The civil date whose noon is Julian Day Number `jdn`.
    public static func date(julianDayNumber jdn: Int64) throws -> GregorianDate { try d(2000, 1, 1).adding(days: jdn - 2_451_545) }

    /// TT of `date` 00:00:00 UTC: UTC midnight of `date` is JD `(JDN − 1) + ½`, plus `32.184 s + (TAI − UTC)`.
    public static func ttOfUTCMidnight(_ date: GregorianDate, taiMinusUTC: Int) -> TTInstant {
        let offsetNs = ttMinusTAINanoseconds + Int64(taiMinusUTC) * nanosecondsPerSecond
        var day = julianDayNumber(date) - 1
        var ns = 43_200 * nanosecondsPerSecond + offsetNs
        if ns >= TTInstant.nanosecondsPerDay { ns -= TTInstant.nanosecondsPerDay; day += 1 }
        return try! TTInstant(julianDay: day, nanosecondsWithinDay: ns)
    }

    public static func segment(of tt: TTInstant) -> Segment {
        if tt < utcStartTT { return .beforeUTC }
        if tt < leapTableEndTT { return .leapTable }
        if tt < continuousUTCStartTT { return .heldOffset }
        return .continuousUTC
    }

    /// TT − UT1 (seconds) before UTC, from the S15.2020 spline; nil from 1972 or before the spline's domain.
    public static func ttMinusUT1Seconds(at tt: TTInstant) -> Double? {
        guard segment(of: tt) == .beforeUTC, tt >= HistoricalUT1.domainStartTT else { return nil }
        return HistoricalUT1.deltaT(at: tt)
    }

    /// TAI − UTC in force at a TT instant; nil before UTC (1972).
    public static func taiMinusUTC(at tt: TTInstant) -> Int? {
        switch segment(of: tt) {
        case .beforeUTC: return nil
        case .heldOffset, .continuousUTC: return continuousTaiMinusUTC
        case .leapTable:
            var value = baseTaiMinusUTC
            for step in leapSecondSteps {
                if tt >= ttOfUTCMidnight(step.utcDate, taiMinusUTC: step.taiMinusUTC) { value = step.taiMinusUTC } else { break }
            }
            return value
        }
    }
}
