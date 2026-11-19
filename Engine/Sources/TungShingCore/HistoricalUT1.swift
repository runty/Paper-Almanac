// Historical clock before UTC: TT − UT1 (ΔT) from the S15.2020 cubic spline, as adjusted and stored by Skyfield 1.55.
//
// Ported from the research reference `docs/handoff/calendar-pack/review/ut1-historical-clock/COEFFICIENTS.json`
// (research commit 21568ea, profile `HK8-S15-SKYFIELD155-REAL-UT1-1972-UTC-v1`): the nineteen active segments for
// 1895–1974 as their exact binary64 values. Source: L. V. Morrison, F. R. Stephenson, C. Y. Hohenkerk and M. Zawilski,
// Table S15.2020 (Addendum 2020 to "Measurement of the Earth's rotation: 720 BC to AD 2015"), doi:10.6084/m9.figshare.13885863.v2,
// CC BY 4.0. Modified: Skyfield 1.55 truncates the spline where its daily table begins and adjusts the 1971–1974 linear
// coefficient (printed 3.157, stored 3.4897025899490037); see NOTICES.md. The research calls this a reference that the
// app may select, not a physical certificate: the segments meet with ±1 ms jumps and its accuracy is not certified.
//
// For a TT Julian day t: J = (t − 1721045)/365.25 (year-like, not centuries), τ = (J − K0)/(K1 − K0) in the segment
// [K0, K1) holding J, ΔT = ((a3 τ + a2) τ + a1) τ + a0 seconds, UT1 = TT − ΔT. Binary64 evaluation agrees with the
// research's exact rational evaluation far below a millisecond, which the clock budget (whole seconds) cannot see.

public enum HistoricalUT1 {
    public static let profile = "HK8-S15-SKYFIELD155-REAL-UT1-1972-UTC-v1"

    public struct Segment: Sendable, Hashable {
        public let lowerYear: Int
        public let upperYear: Int
        public let a3: Double, a2: Double, a1: Double, a0: Double
    }

    public static let segments: [Segment] = [
        Segment(lowerYear: 1895, upperYear: 1900, a3: -0x1.db22d0e560419p-3, a2: 0x1.91a9fbe76c8b4p+1, a1: 0x1.126e978d4fdf4p-3, a0: -0x1.4116872b020c5p+2),
        Segment(lowerYear: 1900, upperYear: 1905, a3: -0x1.41cac083126e9p+0, a2: 0x1.38b4395810625p+1, a1: 0x1.6dc28f5c28f5cp+2, a0: -0x1.fa1cac083126fp+0),
        Segment(lowerYear: 1905, upperYear: 1910, a3: 0x1.70a3d70a3d70ap-1, a2: -0x1.54395810624ddp+0, a1: 0x1.b4fdf3b645a1dp+2, a0: 0x1.3b126e978d4fep+2),
        Segment(lowerYear: 1910, upperYear: 1915, a3: -0x1.a666666666666p-1, a2: 0x1.a978d4fdf3b64p-1, a1: 0x1.951eb851eb852p+2, a0: 0x1.648b439581062p+3),
        Segment(lowerYear: 1915, upperYear: 1920, a3: 0x1.0c49ba5e353f8p-2, a2: -0x1.a49ba5e353f7dp+0, a1: 0x1.6126e978d4fdfp+2, a0: 0x1.17a9fbe76c8b4p+4),
        Segment(lowerYear: 1920, upperYear: 1925, a3: 0x1.0624dd2f1a9fcp-7, a2: -0x1.b645a1cac0831p-1, a1: 0x1.828f5c28f5c29p+1, a0: 0x1.59df3b645a1cbp+4),
        Segment(lowerYear: 1925, upperYear: 1930, a3: 0x1.04189374bc6a8p-3, a2: -0x1.a978d4fdf3b64p-1, a1: 0x1.553f7ced91687p+0, a0: 0x1.7c9fbe76c8b44p+4),
        Segment(lowerYear: 1930, upperYear: 1935, a3: 0x1.22d0e56041893p-3, a2: -0x1.cbc6a7ef9db23p-2, a1: 0x1.a9fbe76c8b439p-5, a0: 0x1.86b020c49ba5ep+4),
        Segment(lowerYear: 1935, upperYear: 1940, a3: 0x1.676c8b4395810p-1, a2: -0x1.6872b020c49bap-6, a1: -0x1.ad0e560418937p-2, a0: 0x1.829fbe76c8b44p+4),
        Segment(lowerYear: 1940, upperYear: 1945, a3: -0x1.1b22d0e560419p+0, a2: 0x1.0b020c49ba5e3p+1, a1: 0x1.a51eb851eb852p+0, a0: 0x1.86d0e56041893p+4),
        Segment(lowerYear: 1945, upperYear: 1950, a3: 0x1.3a5e353f7ced9p-1, a2: -0x1.3b645a1cac083p+0, a1: 0x1.3fdf3b645a1cbp+1, a0: 0x1.b0ccccccccccdp+4),
        Segment(lowerYear: 1950, upperYear: 1953, a3: -0x1.1ba5e353f7ceep-2, a2: 0x1.c28f5c28f5c29p-3, a1: 0x1.2083126e978d5p+0, a0: 0x1.cee978d4fdf3bp+4),
        Segment(lowerYear: 1953, upperYear: 1956, a3: 0x1.43126e978d4fep-1, a2: -0x1.3851eb851eb85p-1, a1: 0x1.795810624dd2fp-1, a0: 0x1.e0083126e978dp+4),
        Segment(lowerYear: 1956, upperYear: 1959, a3: -0x1.9916872b020c5p-1, a2: 0x1.483126e978d50p+0, a1: 0x1.68b4395810625p+0, a0: 0x1.ec28f5c28f5c3p+4),
        Segment(lowerYear: 1959, upperYear: 1962, a3: 0x1.0395810624dd3p-1, a2: -0x1.1d70a3d70a3d7p+0, a1: 0x1.93b645a1cac08p+0, a0: 0x1.05374bc6a7efap+5),
        Segment(lowerYear: 1962, upperYear: 1965, a3: 0x1.978d4fdf3b646p-3, a2: 0x1.9fbe76c8b4396p-2, a1: 0x1.bc6a7ef9db22dp-1, a0: 0x1.0cf7ced916873p+5),
        Segment(lowerYear: 1965, upperYear: 1968, a3: -0x1.a7ef9db22d0e5p-2, a2: 0x1.0083126e978d5p+0, a1: 0x1.2333333333333p+1, a0: 0x1.18be76c8b4396p+5),
        Segment(lowerYear: 1968, upperYear: 1971, a3: 0x1.9db22d0e56042p-3, a2: -0x1.ef9db22d0e560p-3, a1: 0x1.847ae147ae148p+1, a0: 0x1.2fa5e353f7ceep+5),
        Segment(lowerYear: 1971, upperYear: 1974, a3: -0x1.d4fdf3b645a1dp-3, a2: 0x1.74bc6a7ef9db2p-2, a1: 0x1.beae93104c79ep+1, a0: 0x1.479ba5e353f7dp+5),
    ]

    /// Start of the clock's input domain: TT JD 4829307/2 (1898-12-30 00:00 TT).
    public static let domainStartTT = try! TTInstant(julianDay: 2_414_653, nanosecondsWithinDay: 43_200 * 1_000_000_000)

    /// The year-like coordinate J of a TT instant.
    public static func yearCoordinate(_ tt: TTInstant) -> Double {
        (Double(tt.julianDay - 1_721_045) + Double(tt.nanosecondsWithinDay) / Double(TTInstant.nanosecondsPerDay)) / 365.25
    }

    /// ΔT = TT − UT1 in seconds at a TT instant, or nil outside the segments (before 1895 or from 1974).
    public static func deltaT(at tt: TTInstant) -> Double? {
        let j = yearCoordinate(tt)
        guard let s = segments.first(where: { Double($0.lowerYear) <= j && j < Double($0.upperYear) }) else { return nil }
        let tau = (j - Double(s.lowerYear)) / Double(s.upperYear - s.lowerYear)
        return ((s.a3 * tau + s.a2) * tau + s.a1) * tau + s.a0
    }
}
