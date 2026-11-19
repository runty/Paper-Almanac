// Immutable evaluator output: every field the upstream `Lunar` object exposes, plus a typed
// trace of the 宜/忌 route. All collections are arrays in a deterministic order; no
// Dictionary/Set iteration order reaches the output.

import TungShingCore

/// A stem-branch pillar (干支) by sexagenary index 0…59.
public struct SexagenaryPillar: Sendable, Hashable {
    public let index: Int

    public init(index: Int) {
        self.index = floorMod(index, 60)
    }

    public var stemIndex: Int { index % 10 }
    public var branchIndex: Int { index % 12 }
    public var stem: String { UpstreamTables.heavenlyStems[stemIndex] }
    public var branch: String { UpstreamTables.earthlyBranches[branchIndex] }
    /// Upstream two-character label, e.g. 己巳.
    public var label: String { UpstreamTables.sexagenary[index] }
}

/// Upstream moon-phase label (`getPhaseOfMoon`, lunar.py:120).
public enum MoonPhaseLabel: String, Sendable, Hashable {
    case none = ""
    case newMoon = "朔"
    case firstQuarter = "上弦"
    case fullMoon = "望"
    case lastQuarter = "下弦"
}

/// One matched angel/demon tuple with the operands that matched.
public struct AlmanacRuleMatch: Sendable, Hashable {
    public let rule: AlmanacRuleID
    public let name: AlmanacGodName
    public let needle: RuleOperand
    public let container: RuleContainer
    public let recommends: [AlmanacActivity]
    public let avoids: [AlmanacActivity]
}

/// The effect of one imperative step on the candidate lists. Empty arrays mean the step
/// fired but changed nothing.
public struct AlmanacTraceEffect: Sendable, Hashable {
    public let rule: AlmanacRuleID
    public let addedRecommendations: [AlmanacActivity]
    public let removedRecommendations: [AlmanacActivity]
    public let addedAvoidances: [AlmanacActivity]
    public let removedAvoidances: [AlmanacActivity]
    /// Short note in upstream terms (e.g. the policy name chosen by the grade).
    public let note: String

    public init(rule: AlmanacRuleID, addedRecommendations: [AlmanacActivity] = [], removedRecommendations: [AlmanacActivity] = [],
                addedAvoidances: [AlmanacActivity] = [], removedAvoidances: [AlmanacActivity] = [], note: String = "") {
        self.rule = rule
        self.addedRecommendations = UpstreamActivityTables.sortedForOutput(addedRecommendations)
        self.removedRecommendations = UpstreamActivityTables.sortedForOutput(removedRecommendations)
        self.addedAvoidances = UpstreamActivityTables.sortedForOutput(addedAvoidances)
        self.removedAvoidances = UpstreamActivityTables.sortedForOutput(removedAvoidances)
        self.note = note
    }
}

/// Candidate 宜/忌 lists at one stage, in output collation order.
public struct AlmanacActivityLists: Sendable, Hashable {
    public let recommendations: [AlmanacActivity]
    public let avoidances: [AlmanacActivity]

    public init(recommendations: [AlmanacActivity], avoidances: [AlmanacActivity]) {
        self.recommendations = UpstreamActivityTables.sortedForOutput(recommendations)
        self.avoidances = UpstreamActivityTables.sortedForOutput(avoidances)
    }
}

/// A row of the grade table that contributed to `todayLevel`.
public struct AlmanacLevelTableHit: Sendable, Hashable {
    public let key: String
    public let row: LevelTableRow
    public let matchedCompanion: String
}

/// The grade decision of `getTodayThingLevel` (lunar.py:468–612).
public struct AlmanacLevelDecision: Sendable, Hashable {
    /// `todayLevel`: −1 (无) or 0…5.
    public let level: Int
    public let levelName: String
    public let hits: [AlmanacLevelTableHit]
    /// `isDe`.
    public let hasVirtue: Bool
    /// `thingLevel` 0…3.
    public let thingLevel: Int
    public let thingLevelName: String
}

/// Evidence attached to a report; identifiers are stable ASCII, locators are human-readable.
public struct AlmanacEvidence: Sendable, Hashable {
    public let identity: EvidenceID
    public let role: String
    public let locator: String

    public init(identity: EvidenceID, role: String, locator: String) {
        self.identity = identity
        self.role = role
        self.locator = locator
    }
}

/// Typed trace of the 宜/忌 route, in upstream execution order.
public struct AlmanacTrace: Sendable, Hashable {
    /// `officerThings[officer]` seeds (lunar.py:633–634).
    public let officerSeed: AlmanacTraceEffect
    /// `day8CharThing` additions whose key occurs in the day pillar (lunar.py:667–670).
    public let stemBranchAdditions: [AlmanacTraceEffect]
    /// Seasonal and lunar-date additions that fired (lunar.py:683–708).
    public let seasonalAdditions: [AlmanacTraceEffect]
    /// Candidates before the angel/demon tables.
    public let candidatesBeforeGods: AlmanacActivityLists
    public let matchedAngels: [AlmanacRuleMatch]
    public let matchedDemons: [AlmanacRuleMatch]
    /// Deduplicated candidates after both tables (lunar.py:1035–1036).
    public let candidatesAfterGods: AlmanacActivityLists
    public let level: AlmanacLevelDecision
    /// The conflict policy applied for the grade (lunar.py:1074–1081).
    public let conflictResolution: AlmanacTraceEffect
    /// `deIsBadThing` (lunar.py:1089–1097): avoidances retained despite virtue.
    public let virtueRetainedAvoidances: [AlmanacActivity]
    /// Ordered exception blocks that fired (lunar.py:1099–1260).
    public let exceptions: [AlmanacTraceEffect]
    /// Final overlap removal, sentinels and sort (lunar.py:1263–1280).
    public let finalCleanup: [AlmanacTraceEffect]
    public let evidence: [AlmanacEvidence]
}

/// Everything upstream exposes for one date under one profile.
public struct AlmanacDayReport: Sendable, Hashable {
    public let profile: ProfileID
    public let profileDigest: String
    public let gregorian: GregorianDate
    public let evaluationHour: Int

    // Lunar labels (lunar.py:96–117)
    public let lunar: LunarDate
    public let lunarMonthLength: Int
    public let lunarYearLabel: String
    public let lunarMonthLabel: String
    public let lunarDayLabel: String
    public let weekdayLabel: String
    public let moonPhase: MoonPhaseLabel

    // Terms (lunar.py:254–281)
    public let termOnDate: SolarTermDate?
    public let nextTerm: SolarTermDate
    /// Upstream `nextSolarNum`: number of this Gregorian year's terms on or before the date, mod 24.
    public let termsPassedThisYear: Int
    public let eastZodiac: String
    public let starZodiac: String

    // Pillars (lunar.py:284–333)
    public let yearPillar: SexagenaryPillar
    public let monthPillar: SexagenaryPillar
    public let dayPillar: SexagenaryPillar
    public let hourPillar: SexagenaryPillar
    /// The 13 double-hour pillars of the day (`twohour8CharList`).
    public let hourPillars: [SexagenaryPillar]
    /// Upstream `_x` year-label adjustment (−1, 0, 1).
    public let yearLabelAdjustment: Int
    public let yearZodiac: String
    public let zodiacClash: String
    public let zodiacSixHarmony: String
    public let zodiacTripleHarmony: [String]

    // Season (lunar.py:336–342)
    public let monthPositionIndex: Int
    public let seasonIndex: Int
    public let monthPosition: String
    public let season: String
    public let seasonLabel: String

    // Day cycles (lunar.py:388–465)
    public let officer: String
    public let dayGod: String
    public let isYellowPath: Bool
    public let mansion: String
    public let nayin: String
    public let fiveElements: [String]
    public let flyStar: String
    public let luckyDirections: [String]
    public let fetalGod: String
    public let pengTaboo: String
    /// 13 entries, `true` = 凶.
    public let hourLuckIsInauspicious: [Bool]
    public let meridian: String

    // Holidays (lunar.py:349–381; upstream conventions)
    public let legalHolidays: String
    public let otherHolidays: String
    public let otherLunarHolidays: String

    // 宜/忌 route
    public let level: AlmanacLevelDecision
    public let goodGodNames: [AlmanacGodName]
    public let badGodNames: [AlmanacGodName]
    public let recommendations: [AlmanacActivity]
    public let avoidances: [AlmanacActivity]
    public let trace: AlmanacTrace
}
