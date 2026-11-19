// Rule identities and the evaluation environment shared by the angel/demon predicate
// tables and the ordered exception blocks.

/// Identifies one upstream rule, predicate tuple, exception block or postprocessing step by
/// its pinned source location, e.g. `cnlunar/lunar.py:714`.
public struct AlmanacRuleID: Sendable, Hashable, Comparable, CustomStringConvertible {
    public static let evaluatorFile = "cnlunar/lunar.py"
    public static let tablesFile = "cnlunar/config.py"

    /// Human-readable rule name (god name, block summary) in upstream spelling.
    public let name: String
    public let file: String
    public let line: Int

    public init(name: String, file: String = AlmanacRuleID.evaluatorFile, line: Int) {
        self.name = name
        self.file = file
        self.line = line
    }

    /// `file:line` locator, stable across releases of the port.
    public var locator: String { "\(file):\(line)" }
    public var description: String { "\(locator) \(name)" }

    public static func < (lhs: AlmanacRuleID, rhs: AlmanacRuleID) -> Bool {
        (lhs.file, lhs.line, lhs.name) < (rhs.file, rhs.line, rhs.name)
    }
}

/// Which table a god rule belongs to.
public enum GodRuleKind: String, Sendable, Hashable {
    case angel, demon
}

/// The local variables of `get_AngelDemon` (lunar.py:649–665) that predicates read.
public struct RuleEnvironment: Sendable, Hashable {
    /// `d`: the day pillar string, e.g. 己巳.
    public let dayPillar: String
    /// `d[0]`.
    public let dayStem: String
    /// `d[1]`.
    public let dayBranch: String
    /// `den`.
    public let dayBranchIndex: Int
    /// `dhen`.
    public let daySexagenaryIndex: Int
    /// `s[0]`: first character of the mansion label.
    public let mansionInitial: String
    /// `o`: officer label.
    public let officer: String
    /// `sn`.
    public let seasonIndex: Int
    /// `yhn`.
    public let yearStemIndex: Int
    /// `yen`.
    public let yearBranchIndex: Int
    /// `ldn`.
    public let lunarDay: Int
    /// `lmn`.
    public let lunarMonth: Int
    /// `men`: rule month branch index.
    public let monthBranchIndex: Int
    /// `self.lunarMonthType` (仲/季/孟).
    public let monthPosition: String
    /// `tmd`: tomorrow's `(month, day)`.
    public let tomorrow: (month: Int, day: Int)
    /// `t4j` members reconstructible from the term window (this Gregorian year's 立 dates).
    public let fourJueDates: [RuleOperand]
    /// `t4l` members reconstructible from the term window (this Gregorian year's 离 dates).
    public let fourLiDates: [RuleOperand]
    /// The `土王用事` day-difference operand (lunar.py:996), or `.absent` when no 立 of this
    /// Gregorian year lies on or after tomorrow inside the window.
    public let earthKingDays: RuleOperand

    public init(dayPillar: String, dayStem: String, dayBranch: String, dayBranchIndex: Int, daySexagenaryIndex: Int,
                mansionInitial: String, officer: String, seasonIndex: Int, yearStemIndex: Int, yearBranchIndex: Int,
                lunarDay: Int, lunarMonth: Int, monthBranchIndex: Int, monthPosition: String,
                tomorrow: (month: Int, day: Int), fourJueDates: [RuleOperand], fourLiDates: [RuleOperand],
                earthKingDays: RuleOperand) {
        self.dayPillar = dayPillar
        self.dayStem = dayStem
        self.dayBranch = dayBranch
        self.dayBranchIndex = dayBranchIndex
        self.daySexagenaryIndex = daySexagenaryIndex
        self.mansionInitial = mansionInitial
        self.officer = officer
        self.seasonIndex = seasonIndex
        self.yearStemIndex = yearStemIndex
        self.yearBranchIndex = yearBranchIndex
        self.lunarDay = lunarDay
        self.lunarMonth = lunarMonth
        self.monthBranchIndex = monthBranchIndex
        self.monthPosition = monthPosition
        self.tomorrow = tomorrow
        self.fourJueDates = fourJueDates
        self.fourLiDates = fourLiDates
        self.earthKingDays = earthKingDays
    }

    public static func == (lhs: RuleEnvironment, rhs: RuleEnvironment) -> Bool {
        lhs.dayPillar == rhs.dayPillar && lhs.dayBranchIndex == rhs.dayBranchIndex
            && lhs.daySexagenaryIndex == rhs.daySexagenaryIndex && lhs.mansionInitial == rhs.mansionInitial
            && lhs.officer == rhs.officer && lhs.seasonIndex == rhs.seasonIndex && lhs.yearStemIndex == rhs.yearStemIndex
            && lhs.yearBranchIndex == rhs.yearBranchIndex && lhs.lunarDay == rhs.lunarDay && lhs.lunarMonth == rhs.lunarMonth
            && lhs.monthBranchIndex == rhs.monthBranchIndex && lhs.monthPosition == rhs.monthPosition
            && lhs.tomorrow == rhs.tomorrow && lhs.fourJueDates == rhs.fourJueDates && lhs.fourLiDates == rhs.fourLiDates
            && lhs.earthKingDays == rhs.earthKingDays
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(dayPillar)
        hasher.combine(daySexagenaryIndex)
        hasher.combine(monthBranchIndex)
        hasher.combine(yearStemIndex)
        hasher.combine(yearBranchIndex)
        hasher.combine(lunarMonth)
        hasher.combine(lunarDay)
    }
}

/// One `angel`/`demon` tuple: `(name, needle, container, recommend, avoid)`.
public struct GodRule: Sendable {
    public let name: AlmanacGodName
    public let kind: GodRuleKind
    public let identity: AlmanacRuleID
    /// Builds `(tuple[1], tuple[2])` for the day; the loop tests `tuple[1] in tuple[2]`.
    public let operands: @Sendable (RuleEnvironment) -> (needle: RuleOperand, container: RuleContainer)
    public let recommends: [AlmanacActivity]
    public let avoids: [AlmanacActivity]

    public init(_ name: String, kind: GodRuleKind, line: Int, recommends: [String], avoids: [String],
                operands: @escaping @Sendable (RuleEnvironment) -> (needle: RuleOperand, container: RuleContainer)) {
        self.name = AlmanacGodName(name)
        self.kind = kind
        self.identity = AlmanacRuleID(name: name, line: line)
        self.operands = operands
        self.recommends = recommends.map(AlmanacActivity.init(_:))
        self.avoids = avoids.map(AlmanacActivity.init(_:))
    }
}

// Helpers used by the rule tables to express the upstream indexing idioms verbatim.
enum RuleText {
    /// `'…'[i]` on a Python string literal; the tables only index within range.
    static func at(_ literal: String, _ i: Int) -> RuleOperand {
        .text(PyString.char(literal, i) ?? "")
    }

    /// `'…'[a:b]`.
    static func slice(_ literal: String, _ a: Int, _ b: Int) -> RuleOperand {
        .text(PyString.slice(literal, a, b))
    }

    /// `[…][i]` on a Python list of strings.
    static func pick(_ list: [String], _ i: Int) -> String {
        guard i >= 0, i < list.count else { return "" }
        return list[i]
    }

    static func texts(_ items: [String]) -> RuleContainer {
        .elements(items.map(RuleOperand.text))
    }
}
