// The research review's reference civil-date projection (research commit 3f3c5ef,
// `docs/handoff/calendar-pack/REVIEW_AND_GAP_CLOSURE.md` §2, closure CP-03).
//
// For a closed TT interval [L, U], the fixed HK8 reference and an explicitly selected event allowance A, in
// integer nanoseconds:
//
//     shift      = 28,800 s − (32.184 s + (TAI − UTC))
//     civilLower = L + shift − A
//     civilUpper = U + shift + A
//     candidates = every JDN from floor((civilLower + ½ day) / day) through floor((civilUpper + ½ day) / day)
//
// The upper endpoint is included: an interval ending exactly at the next midnight lists the next date. A lower
// endpoint exactly at midnight does not list the previous date. Reversed intervals are refused. The retained
// pack generator compared the upper distance strictly, a closed-interval boundary defect the review records;
// the pack itself is not mutated. This rule is *evidence* beside the pack's own projection, never the active
// policy: the review does not certify any physical allowance, and a revised generator has not been selected.

public enum CivilProjectionReference {
    /// App-owned identifier of this evidence projection.
    public static let policyID = "hk8-continuous-utc-reference-1"

    /// The review's illustrative event allowances (pack model allowance + 1 s): 3 s for conjunctions and 6 s for
    /// solar terms. Inherited scenario values, not certified error bounds.
    public static let illustrativeConjunctionAllowanceSeconds: Int64 = 3
    public static let illustrativeSolarTermAllowanceSeconds: Int64 = 6

    public static func illustrativeAllowanceNanoseconds(for kind: CalendarEventKind) -> Int64 {
        let seconds: Int64 = kind == .conjunction ? illustrativeConjunctionAllowanceSeconds : illustrativeSolarTermAllowanceSeconds
        return seconds * UTCOffsetPolicy.nanosecondsPerSecond
    }

    public enum ProjectionError: Error, Sendable, Equatable {
        case reversedInterval
        case negativeAllowance
    }

    public enum Outcome: Sendable, Hashable {
        /// Candidate civil dates under the segment's TAI − UTC and the given allowance; one date means definite
        /// under this rule.
        case candidates([GregorianDate], segment: UTCOffsetPolicy.Segment, taiMinusUTC: Int, allowanceNanoseconds: Int64)
        /// Before 1972: UT1-based civil time needs ΔT, which this rule does not use.
        case outsideUTCEra
        /// The padded interval crosses a leap-second step; a piecewise policy would be needed.
        case straddlesOffsetChange

        public var dates: [GregorianDate]? {
            if case .candidates(let dates, _, _, _) = self { return dates }
            return nil
        }
    }

    /// Candidate civil dates of the closed TT interval `[lower, upper]` under a constant TAI − UTC.
    public static func candidateDates(lower: TTInstant, upper: TTInstant, taiMinusUTCSeconds: Int, allowanceNanoseconds: Int64) throws -> [GregorianDate] {
        guard lower <= upper else { throw ProjectionError.reversedInterval }
        guard allowanceNanoseconds >= 0 else { throw ProjectionError.negativeAllowance }
        let ns = UTCOffsetPolicy.nanosecondsPerSecond
        let shift = 28_800 * ns - (UTCOffsetPolicy.ttMinusTAINanoseconds + Int64(taiMinusUTCSeconds) * ns)
        let halfDay = TTInstant.nanosecondsPerDay / 2
        // Work as (day, nanoseconds) to stay inside Int64: absolute JD nanoseconds would overflow.
        func civilJDN(_ instant: TTInstant, offset: Int64) -> Int64 {
            let within = instant.nanosecondsWithinDay + offset + halfDay
            return instant.julianDay + floorDiv(within, TTInstant.nanosecondsPerDay)
        }
        let first = civilJDN(lower, offset: shift - allowanceNanoseconds)
        let last = civilJDN(upper, offset: shift + allowanceNanoseconds)
        return try (first...last).map { try UTCOffsetPolicy.date(julianDayNumber: $0) }
    }

    /// The event's root bracket projected under the UTC segment it falls in, with the illustrative allowance.
    public static func project(_ event: CalendarEvent, allowanceNanoseconds: Int64? = nil) -> Outcome {
        let allowance = allowanceNanoseconds ?? illustrativeAllowanceNanoseconds(for: event.kind)
        let lower = event.rootBracket.lowerInclusive, upper = event.rootBracket.upperInclusive
        guard let kLower = UTCOffsetPolicy.taiMinusUTC(at: lower), let kUpper = UTCOffsetPolicy.taiMinusUTC(at: upper) else { return .outsideUTCEra }
        // The allowance can carry an endpoint across a leap-second step; check the padded ends too.
        let paddedLow = shifted(lower, by: -allowance), paddedHigh = shifted(upper, by: allowance)
        guard kLower == kUpper, UTCOffsetPolicy.taiMinusUTC(at: paddedLow) == kLower, UTCOffsetPolicy.taiMinusUTC(at: paddedHigh) == kLower else {
            return .straddlesOffsetChange
        }
        guard let dates = try? candidateDates(lower: lower, upper: upper, taiMinusUTCSeconds: kLower, allowanceNanoseconds: allowance) else {
            return .straddlesOffsetChange
        }
        return .candidates(dates, segment: UTCOffsetPolicy.segment(of: lower), taiMinusUTC: kLower, allowanceNanoseconds: allowance)
    }

    static func shifted(_ instant: TTInstant, by ns: Int64) -> TTInstant {
        var within = instant.nanosecondsWithinDay + ns
        var day = instant.julianDay
        let dayNs = TTInstant.nanosecondsPerDay
        day += floorDiv(within, dayNs)
        within -= floorDiv(within, dayNs) * dayNs
        return (try? TTInstant(julianDay: day, nanosecondsWithinDay: within)) ?? instant
    }

    static func floorDiv(_ a: Int64, _ b: Int64) -> Int64 {
        let q = a / b
        return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q
    }
}
