// E6-01: what the almanac says about one activity on one day, read from the report's final lists and the
// grade's conflict rule, with the trace steps that touched the token. A pure function of the report: no
// synonym expansion (嫁娶, 结婚姻 and 纳采 are three tokens, as in the source) and no inference beyond the trace.

/// What the almanac says about one activity on one day.
public enum AlmanacActivityStanding: String, Sendable, Hashable, Codable {
    /// In the final 宜 list.
    case favorable
    /// In the final 忌 list.
    case avoid
    /// The grade's 諸事皆忌 (conflict rule `nothingGood`, lunar.py:1065): every activity is avoided.
    case avoidAll
    /// In neither list. 诸事不忌 never makes an activity favourable, and an emptied 宜 list stays here.
    case noStatement

    /// The one rule every projection uses, so the report, the stored day and the widget feed agree.
    /// `avoidsEverything` is the grade's conflict rule, never the 诸事不宜 sentinel, which an emptied 宜 list
    /// also produces (lunar.py:1275). The sentinels themselves are not activities and have no standing.
    public init(_ activity: AlmanacActivity, isRecommended: Bool, isAvoided: Bool, avoidsEverything: Bool) {
        if activity.isSentinel { self = .noStatement }
        else if avoidsEverything { self = .avoidAll }
        else if isAvoided { self = .avoid }
        else if isRecommended { self = .favorable }
        else { self = .noStatement }
    }
}

/// Where in the 宜/忌 route a step ran, in upstream execution order.
public enum AlmanacTraceStage: String, Sendable, Hashable, Codable, CaseIterable {
    case officerSeed, stemBranch, seasonal, angel, demon, conflict, exception, cleanup
}

/// One step of the 宜/忌 route. Angel and demon matches are steps whose effect lists what the god names; their
/// rule's name is the god's name.
public struct AlmanacTraceStep: Sendable, Hashable {
    public let stage: AlmanacTraceStage
    public let effect: AlmanacTraceEffect

    public init(stage: AlmanacTraceStage, effect: AlmanacTraceEffect) {
        self.stage = stage
        self.effect = effect
    }

    /// What this step did to one token, in the order 宜 added, 宜 removed, 忌 added, 忌 removed.
    public func changes(to activity: AlmanacActivity) -> [AlmanacTokenChange] {
        var out: [AlmanacTokenChange] = []
        if effect.addedRecommendations.contains(activity) { out.append(.addedRecommendation) }
        if effect.removedRecommendations.contains(activity) { out.append(.removedRecommendation) }
        if effect.addedAvoidances.contains(activity) { out.append(.addedAvoidance) }
        if effect.removedAvoidances.contains(activity) { out.append(.removedAvoidance) }
        return out
    }
}

/// How one step touched one token.
public enum AlmanacTokenChange: String, Sendable, Hashable, Codable {
    case addedRecommendation, removedRecommendation, addedAvoidance, removedAvoidance
}

/// One trace step that touched an activity token.
public struct AlmanacActivityStep: Sendable, Hashable {
    public let stage: AlmanacTraceStage
    public let rule: AlmanacRuleID
    public let change: AlmanacTokenChange
    /// The step's note in upstream terms: the policy the grade chose, an exception's caveat.
    public let note: String
}

/// The almanac's verdict on one activity for one day, with its explanation.
public struct AlmanacActivityVerdict: Sendable, Hashable {
    public let activity: AlmanacActivity
    public let standing: AlmanacActivityStanding
    /// The steps that touched the token, in upstream execution order. On an avoid-all day it ends with the
    /// grade's conflict rule; a removed candidate's last step names the rule that removed it.
    public let steps: [AlmanacActivityStep]
}

extension AlmanacActivity {
    /// The output sentinels 诸事不宜 and 诸事不忌: list placeholders, not activities.
    public var isSentinel: Bool { self == .nothingSuitable || self == .nothingAvoided }

    /// Every token the pinned rules can put in a 宜 or 忌 list, in the order the tables first mention it: the officer
    /// seeds, the stem/branch additions, every angel and demon rule, then the seasonal additions. The exceptions only
    /// remove or re-add these, and the sentinels are not activities. A date search asks only for these tokens.
    public static let vocabulary: [AlmanacActivity] = {
        var seen: Set<AlmanacActivity> = []
        var out: [AlmanacActivity] = []
        func add(_ activities: [AlmanacActivity]) {
            for a in activities where !a.isSentinel && seen.insert(a).inserted { out.append(a) }
        }
        for entry in UpstreamActivityTables.officerThings { add(entry.recommends); add(entry.avoids) }
        for entry in UpstreamActivityTables.stemBranchThings { add(entry.recommends); add(entry.avoids) }
        for rule in UpstreamAngelRules.rules { add(rule.recommends); add(rule.avoids) }
        for rule in UpstreamDemonRules.rules { add(rule.recommends); add(rule.avoids) }
        add([.quYu, .tianLie, .faMu, .zhengShouZuJia, .zhengRong, .tiTou, .qiuYiLiaoBing])
        return out
    }()
}

extension AlmanacRuleID {
    /// The grade's 諸事皆忌 policy (lunar.py:1065), which replaces both lists with 诸事不宜.
    public static let nothingGood = AlmanacRuleID(name: "nothingGood", line: 1065)
}

extension AlmanacTrace {
    /// Whether the grade avoids everything (諸事皆忌), read from the conflict rule, never from the sentinel.
    public var avoidsEverything: Bool { conflictResolution.rule == .nothingGood }

    /// Every step of the route in upstream execution order, final cleanup included.
    public var steps: [AlmanacTraceStep] {
        func god(_ m: AlmanacRuleMatch) -> AlmanacTraceEffect {
            AlmanacTraceEffect(rule: m.rule, addedRecommendations: m.recommends, addedAvoidances: m.avoids)
        }
        return [AlmanacTraceStep(stage: .officerSeed, effect: officerSeed)]
            + stemBranchAdditions.map { AlmanacTraceStep(stage: .stemBranch, effect: $0) }
            + seasonalAdditions.map { AlmanacTraceStep(stage: .seasonal, effect: $0) }
            + matchedAngels.map { AlmanacTraceStep(stage: .angel, effect: god($0)) }
            + matchedDemons.map { AlmanacTraceStep(stage: .demon, effect: god($0)) }
            + [AlmanacTraceStep(stage: .conflict, effect: conflictResolution)]
            + exceptions.map { AlmanacTraceStep(stage: .exception, effect: $0) }
            + finalCleanup.map { AlmanacTraceStep(stage: .cleanup, effect: $0) }
    }
}

extension Sequence<AlmanacTraceStep> {
    /// The steps that touched one token, one entry per change, in order.
    public func touching(_ activity: AlmanacActivity) -> [AlmanacActivityStep] {
        flatMap { step in
            step.changes(to: activity).map { AlmanacActivityStep(stage: step.stage, rule: step.effect.rule, change: $0, note: step.effect.note) }
        }
    }
}

extension AlmanacDayReport {
    /// The standing alone: avoid-all on a 諸事皆忌 day, else 忌, else 宜, else no statement.
    public func standing(for activity: AlmanacActivity) -> AlmanacActivityStanding {
        AlmanacActivityStanding(activity, isRecommended: recommendations.contains(activity),
                                isAvoided: avoidances.contains(activity), avoidsEverything: trace.avoidsEverything)
    }

    /// The standing with the trace steps that explain it.
    public func verdict(for activity: AlmanacActivity) -> AlmanacActivityVerdict {
        let standing = standing(for: activity)
        var steps = trace.steps.touching(activity)
        // The grade's rule applies to every activity, including one no rule listed that day.
        if standing == .avoidAll, !steps.contains(where: { $0.stage == .conflict }) {
            steps.append(AlmanacActivityStep(stage: .conflict, rule: trace.conflictResolution.rule, change: .addedAvoidance,
                                             note: trace.conflictResolution.note))
        }
        return AlmanacActivityVerdict(activity: activity, standing: standing, steps: steps)
    }
}
