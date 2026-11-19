// E2-01: named almanac profiles. A profile freezes the pinned upstream source and its
// constructor options. Its conventions describe how the upstream evaluator interprets
// calendar facts; they are NOT calendar facts and never override the E1 calendar profile.

import TungShingCore

/// Upstream `godType` constructor option.
public enum AlmanacGodType: String, Sendable, Hashable, CaseIterable {
    /// `godType="8char"`: rule month from the solar month pillar (月柱) branch.
    case eightChar = "8char"
    /// `godType="cnlunar"`: rule month from the lunar month number (`(lunarMonth + 1) % 12`).
    case cnlunar
}

/// Upstream `year8Char` constructor option: how the rule year (年柱/生肖) label is chosen.
public enum AlmanacYearLabelMode: String, Sendable, Hashable, CaseIterable {
    /// `year8Char="year"`: the lunar year (changes at lunar New Year).
    case lunarNewYear = "year"
    /// `year8Char="beginningOfSpring"`: adjusted by the upstream 立春 heuristic (`getBeginningOfSpringX`).
    case beginningOfSpring
}

/// Upstream `yeargod` constructor option.
public enum AlmanacYearGodMode: String, Sendable, Hashable, CaseIterable {
    /// `yeargod="duty"`: rules whose name contains 岁 are evaluated.
    case duty
    /// `yeargod="noduty"`: rules whose name contains 岁 are skipped.
    case noduty
}

/// The pinned upstream source of a profile.
public struct AlmanacSourcePin: Sendable, Hashable {
    public let repository: String
    public let commit: String
    public let license: String

    public init(repository: String, commit: String, license: String) {
        self.repository = repository
        self.commit = commit
        self.license = license
    }

    /// OPN48/cnlunar at the audited commit.
    public static let cnlunar3f674fe = AlmanacSourcePin(
        repository: "https://github.com/OPN48/cnlunar",
        commit: "3f674fe0f458b480c79eaaf5464f43f4bc815a91",
        license: "MIT")
}

/// Evaluator conventions that are interpretation choices of the upstream software.
///
/// None of these is a calendar fact. The E1 calendar profile (accepted event projections,
/// Hong Kong civil dates, lunar month identities) is the only source of calendar facts; an
/// almanac profile consumes those facts and never reinterprets or overrides them.
public enum AlmanacConvention: String, Sendable, Hashable, CaseIterable {
    /// Solar-month (建月) boundaries fall on the civil date of each 節 as supplied, not on the instant.
    case solarMonthBoundaryByTermCivilDate
    /// The day pillar advances at 23:00 (`twohourNum == 12`), while mansions and the nine-star
    /// cycle keep the civil date.
    case dayPillarAdvancesAtTwentyThreeHours
    /// The rule year label follows the profile's `year8Char` mode, including the upstream 立春 heuristic.
    case yearLabelByProfileMode
    /// Term counting is per Gregorian year (`nextSolarNum` resets after 冬至), which also drives the
    /// upstream 立春 heuristic in late December.
    case termCountingPerGregorianYear
}

/// A disclosed correction that a separately named derivative profile applies to the pinned source (research V1 R02,
/// `docs/handoff/v1/almanac-audit/REPORT.md` §3–4). A profile without corrections keeps every upstream behaviour.
public enum AlmanacCorrection: String, Sendable, Hashable, CaseIterable, Comparable {
    /// `chineseZodiacNameList[((lunarYear − 4) % 12 − x) % 12]`: the zodiac index wraps instead of overflowing between
    /// 立春 and lunar New Year (lunar.py:134; 2032-02-04…10).
    case zodiacIndexWrap
    /// `springYear = GregorianYear − (date < this year's 立春 day ? 1 : 0)` and `x = lunarYear − springYear`, a whole-day
    /// boundary, instead of the `nextSolarNum < 3` test that regresses the year from 冬至 to 31 December (lunar.py:64–92).
    case springYearFromLichunDay

    public static func < (lhs: AlmanacCorrection, rhs: AlmanacCorrection) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A frozen, named almanac evaluation profile.
public struct AlmanacProfile: Sendable, Hashable {
    public let identity: ProfileID
    public let source: AlmanacSourcePin
    public let godType: AlmanacGodType
    public let yearLabelMode: AlmanacYearLabelMode
    public let yearGodMode: AlmanacYearGodMode
    /// Wall-clock hour (0…23) at which upstream is evaluated; only the hour matters upstream.
    public let evaluationHour: Int
    /// Conventions this profile relies on (documentation; the evaluator applies all of them).
    public let conventions: [AlmanacConvention]
    /// Revision of this Swift port of the evaluator; part of the digest.
    public let portRevision: String
    /// Disclosed corrections to the pinned source; empty for a source-faithful profile.
    public let corrections: Set<AlmanacCorrection>

    public init(identity: ProfileID, source: AlmanacSourcePin, godType: AlmanacGodType, yearLabelMode: AlmanacYearLabelMode,
                yearGodMode: AlmanacYearGodMode, evaluationHour: Int, portRevision: String = AlmanacProfile.currentPortRevision,
                corrections: Set<AlmanacCorrection> = []) throws {
        guard (0...23).contains(evaluationHour) else { throw AlmanacProfileError.invalidEvaluationHour(evaluationHour) }
        self.identity = identity
        self.source = source
        self.godType = godType
        self.yearLabelMode = yearLabelMode
        self.yearGodMode = yearGodMode
        self.evaluationHour = evaluationHour
        self.conventions = AlmanacConvention.allCases
        self.portRevision = portRevision
        self.corrections = corrections
    }

    /// Revision tag of the port; bump when the port's behaviour changes.
    public static let currentPortRevision = "e2-port-1"

    /// The selected application candidate: `godType="8char"`, `year8Char="beginningOfSpring"`,
    /// `yeargod="duty"`, evaluated at 12:00 under the Hong Kong civil-label convention.
    public static let appNoon: AlmanacProfile = try! AlmanacProfile(
        identity: try! ProfileID("cnlunar-3f674fe-8char-noon"),
        source: .cnlunar3f674fe, godType: .eightChar, yearLabelMode: .beginningOfSpring, yearGodMode: .duty, evaluationHour: 12)

    /// Research V1's corrected derivative of `appNoon` (`cnlunar-3f674fe-8char-noon-v1-calendar-fixes-draft1`): the same
    /// options and every upstream rule, with the zodiac wrap and the 立春-day spring year. Defined and verified over
    /// 2020–2035 on the V1 calendar route; its results differ from `appNoon` only from 冬至 to 31 December and on
    /// 2032-02-04…10, where `appNoon` has no result.
    public static let v1Corrected: AlmanacProfile = try! AlmanacProfile(
        identity: try! ProfileID("cnlunar-3f674fe-8char-noon-v1-calendar-fixes-draft1"),
        source: .cnlunar3f674fe, godType: .eightChar, yearLabelMode: .beginningOfSpring, yearGodMode: .duty, evaluationHour: 12,
        portRevision: "v1-port-1", corrections: [.zodiacIndexWrap, .springYearFromLichunDay])

    /// Research P3's corrected almanac (`cnlunar-3f674fe-8char-noon-calendar-fixes-2020-2045-candidate1`): V1's two
    /// corrections and port under a new ID, fed only by the 2020–2045 calendar.
    public static let calendar2045Corrected: AlmanacProfile = try! AlmanacProfile(
        identity: try! ProfileID("cnlunar-3f674fe-8char-noon-calendar-fixes-2020-2045-candidate1"),
        source: .cnlunar3f674fe, godType: .eightChar, yearLabelMode: .beginningOfSpring, yearGodMode: .duty, evaluationHour: 12,
        portRevision: "v1-port-1", corrections: [.zodiacIndexWrap, .springYearFromLichunDay])

    /// The research's 1901–2100 almanac (`cnlunar-3f674fe-8char-noon-calendar-fixes-1901-2100-v1`): the same corrected
    /// rules and port under a new ID, fed only by the 1901–2100 calendar.
    public static let calendar2100Corrected: AlmanacProfile = try! AlmanacProfile(
        identity: try! ProfileID("cnlunar-3f674fe-8char-noon-calendar-fixes-1901-2100-v1"),
        source: .cnlunar3f674fe, godType: .eightChar, yearLabelMode: .beginningOfSpring, yearGodMode: .duty, evaluationHour: 12,
        portRevision: "v1-port-1", corrections: [.zodiacIndexWrap, .springYearFromLichunDay])

    /// The comparison baseline: `year8Char="year"` at 00:00 (research reference baseline).
    public static let baselineMidnightYear: AlmanacProfile = try! AlmanacProfile(
        identity: try! ProfileID("cnlunar-3f674fe-8char-midnight-year"),
        source: .cnlunar3f674fe, godType: .eightChar, yearLabelMode: .lunarNewYear, yearGodMode: .duty, evaluationHour: 0)

    /// Canonical value of every digest-relevant option (restricted canonical JSON v1).
    public var canonicalValue: CanonicalValue {
        var fields: [String: CanonicalValue] = [
            "identity": .string(identity.value),
            "source": .object([
                "repository": .string(source.repository),
                "commit": .string(source.commit),
                "license": .string(source.license),
            ]),
            "godType": .string(godType.rawValue),
            "year8Char": .string(yearLabelMode.rawValue),
            "yeargod": .string(yearGodMode.rawValue),
            "evaluationHour": .string(String(evaluationHour)),
            "conventions": .array(conventions.map { .string($0.rawValue) }),
            "portRevision": .string(portRevision),
        ]
        // Only a corrected profile carries the key, so a source-faithful profile keeps its digest.
        if !corrections.isEmpty { fields["corrections"] = .array(corrections.sorted().map { .string($0.rawValue) }) }
        return .object(fields)
    }

    /// Deterministic profile digest (`TS-E1` / role `almanacProfile` / canonical JSON v1).
    public func digest() throws -> String {
        try CanonicalJSON.digest(role: .almanacProfile, value: canonicalValue)
    }

    /// Upstream `isYeargodDuty` (lunar.py:31).
    var isYearGodDuty: Bool { yearGodMode == .duty }
}

public enum AlmanacProfileError: Error, Sendable, Hashable {
    case invalidEvaluationHour(Int)
}
