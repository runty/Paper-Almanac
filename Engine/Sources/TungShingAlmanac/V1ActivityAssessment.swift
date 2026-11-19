// Research V1-R03 §4–5 (docs/handoff/v1/input-contract/CONTRACT.md and reference.py at research 081db5b): the result
// for one named activity on one day, with the layer's status, the final-resolution basis and the day's global
// annotations. The final lists are validated before any activity is read, so a malformed day is a stated conflict or
// error, never a quiet "no statement". Favourites are applied afterwards and never change a result.

/// The status of a result, in R03's words.
public enum V1ResultStatus: String, Sendable, Hashable, Codable, CaseIterable {
    case available
    case noStatement = "no_statement"
    case disabled
    case inputMissing = "input_missing"
    case invalidInput = "invalid_input"
    case unsupported
    case sourceConflict = "source_conflict"
    case calculationError = "calculation_error"
    case ambiguous
}

public enum V1ActivityJudgment: String, Sendable, Hashable, Codable {
    case recommended, avoided
}

/// Why an available result says what it says.
public enum V1ActivityBasis: String, Sendable, Hashable, Codable {
    case explicitPositive = "explicit_positive"
    case explicitNegative = "explicit_negative"
    /// The grade's 諸事皆忌, which avoids every activity.
    case globalRule = "global_rule"
}

/// A statement about the whole day that every activity's result carries and filtering never removes.
public enum V1DayAnnotation: String, Sendable, Hashable, Codable {
    /// The grade avoids everything (諸事皆忌).
    case globalAvoidance = "global_avoidance"
    /// The 宜 list holds only 诸事不宜 under an ordinary policy: no recommendations, not a global avoidance.
    case noPositiveStatements = "no_positive_statements"
    /// The 忌 list holds only 诸事不忌: no stated taboos, not universal suitability.
    case noStatedTaboos = "no_stated_taboos"
}

/// The catalogue identity of an activity: `cnlunar-3f674fe:activity:` and the exact source token. Opaque: never
/// translated, case-folded, trimmed or split to decide meaning.
public enum V1ActivityID {
    public static let prefix = "cnlunar-3f674fe:activity:"

    public static func id(_ activity: AlmanacActivity) -> String { prefix + activity.rawValue }

    /// The source token of a catalogue ID, or nil for anything else.
    public static func token(_ id: String) -> String? {
        id.hasPrefix(prefix) ? String(id.dropFirst(prefix.count)) : nil
    }

    /// The 81 tokens the profile emits, the catalogue a favourite or a request may name.
    public static let catalogue: Set<String> = Set(AlmanacActivity.vocabulary.map(\.rawValue))
}

/// One activity's result.
public struct V1ActivityAssessment: Sendable, Hashable {
    public let status: V1ResultStatus
    public let judgment: V1ActivityJudgment?
    public let basis: V1ActivityBasis?
    public let annotations: [V1DayAnnotation]
    /// The reason code of a status other than available or no statement, as R03 names it.
    public let reason: String?

    init(status: V1ResultStatus, judgment: V1ActivityJudgment? = nil, basis: V1ActivityBasis? = nil,
         annotations: [V1DayAnnotation] = [], reason: String? = nil) {
        self.status = status
        self.judgment = judgment
        self.basis = basis
        self.annotations = annotations
        self.reason = reason
    }
}

/// A day's almanac layer, validated: the final lists with their annotations, or the layer's own status.
public struct V1ActivityLayer: Sendable, Hashable {
    public enum State: Sendable, Hashable {
        case available(positive: Set<String>, negative: Set<String>, avoidsEverything: Bool, annotations: [V1DayAnnotation])
        case unavailable(V1ResultStatus, reason: String?)
    }

    public let state: State

    /// The source's four resolution policies (lunar.py `thingLevelNames`).
    public static let policies: Set<String> = Set(UpstreamLevelTable.thingLevelNames)
    static let globalPolicy = "诸事皆忌"

    /// A layer that is disabled, failed or otherwise unavailable: every activity carries its status.
    public init(status: V1ResultStatus, reason: String?) {
        state = .unavailable(status, reason: reason)
    }

    /// A layer from the source's final lists and policy, validated in R03's order.
    public init(yi: [String], ji: [String], policy: String, catalogue: Set<String> = V1ActivityID.catalogue) {
        let noGood = AlmanacActivity.nothingSuitable.rawValue, noBad = AlmanacActivity.nothingAvoided.rawValue
        guard Self.policies.contains(policy) else { state = .unavailable(.sourceConflict, reason: "unknown_policy"); return }
        guard !yi.isEmpty, !ji.isEmpty else { state = .unavailable(.calculationError, reason: "incomplete_final_lists"); return }
        guard (yi + ji).allSatisfy({ catalogue.contains($0) || $0 == noGood || $0 == noBad }) else {
            state = .unavailable(.sourceConflict, reason: "unknown_source_token"); return
        }
        if policy == Self.globalPolicy {
            guard yi == [noGood], ji == [noGood] else { state = .unavailable(.sourceConflict, reason: "inconsistent_sentinel"); return }
            state = .available(positive: [], negative: [], avoidsEverything: true, annotations: [.globalAvoidance])
            return
        }
        let sentinelMisplaced = yi.contains(noBad) || ji.contains(noGood)
            || (yi.contains(noGood) && yi != [noGood]) || (ji.contains(noBad) && ji != [noBad])
        guard !sentinelMisplaced else { state = .unavailable(.sourceConflict, reason: "inconsistent_sentinel"); return }
        let positive = Set(yi).subtracting([noGood]), negative = Set(ji).subtracting([noBad])
        guard positive.isDisjoint(with: negative) else { state = .unavailable(.sourceConflict, reason: "activity_in_both_lists"); return }
        var annotations: [V1DayAnnotation] = []
        if yi == [noGood] { annotations.append(.noPositiveStatements) }
        if ji == [noBad] { annotations.append(.noStatedTaboos) }
        state = .available(positive: positive, negative: negative, avoidsEverything: false, annotations: annotations)
    }

    /// A layer from an evaluated day.
    public init(report: AlmanacDayReport) {
        self.init(yi: report.recommendations.map(\.rawValue), ji: report.avoidances.map(\.rawValue), policy: report.level.thingLevelName)
    }

    /// The day's global annotations; empty for an unavailable layer.
    public var annotations: [V1DayAnnotation] {
        if case .available(_, _, _, let annotations) = state { return annotations }
        return []
    }

    /// One catalogue activity's result. An unknown ID is unsupported before the layer is read; an unavailable layer
    /// passes its status on and is never read as no statement or no taboos.
    public func assess(_ activityID: String, catalogue: Set<String> = V1ActivityID.catalogue) -> V1ActivityAssessment {
        guard let token = V1ActivityID.token(activityID), catalogue.contains(token) else {
            return V1ActivityAssessment(status: .unsupported, reason: "unknown_activity")
        }
        switch state {
        case .unavailable(let status, let reason):
            return V1ActivityAssessment(status: status, reason: reason)
        case .available(let positive, let negative, let avoidsEverything, let annotations):
            if avoidsEverything { return V1ActivityAssessment(status: .available, judgment: .avoided, basis: .globalRule, annotations: annotations) }
            if negative.contains(token) { return V1ActivityAssessment(status: .available, judgment: .avoided, basis: .explicitNegative, annotations: annotations) }
            if positive.contains(token) { return V1ActivityAssessment(status: .available, judgment: .recommended, basis: .explicitPositive, annotations: annotations) }
            return V1ActivityAssessment(status: .noStatement, annotations: annotations)
        }
    }
}

/// R03's favourite orderings, applied after every result exists.
public enum V1ActivityOrdering {
    public enum Refusal: String, Error, Sendable { case favoriteActivityIDs = "favorite_activity_ids", duplicateFavorite = "duplicate_favorite" }

    /// Favourites must be distinct catalogue IDs; sentinels and free phrases cannot be chosen.
    public static func validateFavorites(_ favorites: [String], catalogue: Set<String> = V1ActivityID.catalogue) -> Refusal? {
        guard favorites.allSatisfy({ V1ActivityID.token($0).map(catalogue.contains) ?? false }) else { return .favoriteActivityIDs }
        return Set(favorites).count == favorites.count ? nil : .duplicateFavorite
    }
}
