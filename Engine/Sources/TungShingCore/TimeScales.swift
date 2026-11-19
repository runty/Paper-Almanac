// Terrestrial Time instants as exact integers. Never UTC, never UT1.

public struct TTInstant: Sendable, Hashable, Comparable {
    public static let nanosecondsPerDay: Int64 = 86_400_000_000_000

    /// floor(JD_TT); TT Julian days begin at noon.
    public let julianDay: Int64
    /// Nanoseconds since that TT Julian noon, in 0 ..< 86_400_000_000_000.
    public let nanosecondsWithinDay: Int64

    public init(julianDay: Int64, nanosecondsWithinDay: Int64) throws {
        guard nanosecondsWithinDay >= 0, nanosecondsWithinDay < TTInstant.nanosecondsPerDay else {
            throw CoreValidationError.invalidInstant(julianDay: julianDay, nanoseconds: nanosecondsWithinDay)
        }
        self.julianDay = julianDay
        self.nanosecondsWithinDay = nanosecondsWithinDay
    }

    public static func < (lhs: TTInstant, rhs: TTInstant) -> Bool {
        (lhs.julianDay, lhs.nanosecondsWithinDay) < (rhs.julianDay, rhs.nanosecondsWithinDay)
    }

    /// Total nanoseconds relative to JD 0 noon, for differences only. Fits Int64 for the domain.
    public var totalNanoseconds: Int64 {
        julianDay * TTInstant.nanosecondsPerDay + nanosecondsWithinDay
    }
}

/// Numerical root enclosure of an event instant: lower ≤ nominal ≤ upper.
public struct TTEventBracket: Sendable, Hashable {
    public let lowerInclusive: TTInstant
    public let upperInclusive: TTInstant

    public init(lowerInclusive: TTInstant, upperInclusive: TTInstant) throws {
        guard lowerInclusive <= upperInclusive else { throw CoreValidationError.invalidBracket }
        self.lowerInclusive = lowerInclusive
        self.upperInclusive = upperInclusive
    }

    public func encloses(_ instant: TTInstant) -> Bool {
        lowerInclusive <= instant && instant <= upperInclusive
    }
}
