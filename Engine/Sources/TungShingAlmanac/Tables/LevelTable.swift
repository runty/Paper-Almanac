// The 宜忌等第 lookup used by `getTodayThingLevel` (lunar.py:468–612), ported verbatim.

/// One row of `badGodDic[key]`: `(monthBranches, godNames, level)`.
public struct LevelTableRow: Sendable, Hashable {
    /// `item[0]`: the rule-month branches as one string; the test is `month8Char[1] in item[0]`.
    public let monthBranches: String
    /// `item[1]`: names that must appear among today's gods (god names or `<officer>日`).
    public let companions: [String]
    /// `item[2]`.
    public let level: Int
}

/// `badGodDic` (lunar.py:472–556) as an ordered list of `(key, rows)`; keys are matched
/// against `goodGodName + badGodName + [officer + "日"]`.
public enum UpstreamLevelTable {
    public static let entries: [(key: String, rows: [LevelTableRow])] = [
        ("平日", [
            LevelTableRow(monthBranches: "亥", companions: ["相日", "时德", "六合"], level: 0),
            LevelTableRow(monthBranches: "巳", companions: ["相日", "六合", "月刑"], level: 1),
            LevelTableRow(monthBranches: "申", companions: ["相日", "月害"], level: 2),
            LevelTableRow(monthBranches: "寅", companions: ["相日", "月害", "月刑"], level: 3),
            LevelTableRow(monthBranches: "卯午酉", companions: ["天吏"], level: 3),
            LevelTableRow(monthBranches: "辰戌丑未", companions: ["月煞"], level: 4),
            LevelTableRow(monthBranches: "子", companions: ["天吏", "月刑"], level: 4),
        ]),
        ("收日", [
            LevelTableRow(monthBranches: "寅申", companions: ["长生", "六合", "劫煞"], level: 0),
            LevelTableRow(monthBranches: "巳亥", companions: ["长生", "劫煞"], level: 2),
            LevelTableRow(monthBranches: "辰未", companions: ["月害"], level: 2),
            LevelTableRow(monthBranches: "子午酉", companions: ["大时"], level: 3),
            LevelTableRow(monthBranches: "丑戌", companions: ["月刑"], level: 3),
            LevelTableRow(monthBranches: "卯", companions: ["大时"], level: 4),
        ]),
        ("闭日", [
            LevelTableRow(monthBranches: "子午卯酉", companions: ["王日"], level: 3),
            LevelTableRow(monthBranches: "辰戌丑未", companions: ["官日", "天吏"], level: 3),
            LevelTableRow(monthBranches: "寅申巳亥", companions: ["月煞"], level: 4),
        ]),
        ("劫煞", [
            // lunar.py:496 and 499 are commented-out rows and are not ported.
            LevelTableRow(monthBranches: "寅申", companions: ["长生", "六合"], level: 0),
            LevelTableRow(monthBranches: "辰戌丑未", companions: ["除日", "相日"], level: 1),
            LevelTableRow(monthBranches: "巳亥", companions: ["长生", "月害"], level: 2),
            LevelTableRow(monthBranches: "子午卯酉", companions: ["执日"], level: 3),
        ]),
        ("灾煞", [
            LevelTableRow(monthBranches: "寅申巳亥", companions: ["开日"], level: 1),
            LevelTableRow(monthBranches: "辰戌丑未", companions: ["满日", "民日"], level: 2),
            LevelTableRow(monthBranches: "子午", companions: ["月破"], level: 4),
            LevelTableRow(monthBranches: "卯酉", companions: ["月破", "月厌"], level: 5),
        ]),
        ("月煞", [
            LevelTableRow(monthBranches: "卯酉", companions: ["六合", "危日"], level: 1),
            LevelTableRow(monthBranches: "子午", companions: ["月害", "危日"], level: 3),
            // lunar.py:512–513 are commented-out rows and are not ported.
        ]),
        ("月刑", [
            LevelTableRow(monthBranches: "巳", companions: ["平日", "六合", "相日"], level: 1),
            LevelTableRow(monthBranches: "寅", companions: ["相日", "月害", "平日"], level: 3),
            LevelTableRow(monthBranches: "辰酉亥", companions: ["建日"], level: 3),
            // lunar.py:519 is a commented-out row and is not ported.
            LevelTableRow(monthBranches: "子", companions: ["平日", "天吏"], level: 4),
            LevelTableRow(monthBranches: "卯", companions: ["收日", "大时", "天破"], level: 4),
            LevelTableRow(monthBranches: "未申", companions: ["月破"], level: 4),
            LevelTableRow(monthBranches: "午", companions: ["月建", "月厌", "德大会"], level: 4),
        ]),
        ("月害", [
            LevelTableRow(monthBranches: "卯酉", companions: ["守日", "除日"], level: 2),
            LevelTableRow(monthBranches: "丑未", companions: ["执日", "大时"], level: 2),
            LevelTableRow(monthBranches: "巳亥", companions: ["长生", "劫煞"], level: 2),
            LevelTableRow(monthBranches: "申", companions: ["相日", "平日"], level: 2),
            LevelTableRow(monthBranches: "子午", companions: ["月煞"], level: 3),
            LevelTableRow(monthBranches: "辰戌", companions: ["官日", "闭日", "天吏"], level: 3),
            LevelTableRow(monthBranches: "寅", companions: ["相日", "平日", "月刑"], level: 3),
        ]),
        ("月厌", [
            LevelTableRow(monthBranches: "寅申", companions: ["成日"], level: 2),
            LevelTableRow(monthBranches: "丑未", companions: ["开日"], level: 2),
            LevelTableRow(monthBranches: "辰戌", companions: ["定日"], level: 3),
            LevelTableRow(monthBranches: "巳亥", companions: ["满日"], level: 3),
            LevelTableRow(monthBranches: "子", companions: ["月建", "德大会"], level: 4),
            LevelTableRow(monthBranches: "午", companions: ["月建", "月刑", "德大会"], level: 4),
            LevelTableRow(monthBranches: "卯酉", companions: ["月破", "灾煞"], level: 5),
        ]),
        ("大时", [
            LevelTableRow(monthBranches: "寅申巳亥", companions: ["除日", "官日"], level: 0),
            LevelTableRow(monthBranches: "辰戌", companions: ["执日", "六合"], level: 0),
            LevelTableRow(monthBranches: "丑未", companions: ["执日", "月害"], level: 2),
            LevelTableRow(monthBranches: "子午酉", companions: ["收日"], level: 3),
            LevelTableRow(monthBranches: "卯", companions: ["收日", "月刑"], level: 4),
        ]),
        ("天吏", [
            LevelTableRow(monthBranches: "寅申巳亥", companions: ["危日"], level: 2),
            LevelTableRow(monthBranches: "辰戌丑未", companions: ["闭日"], level: 3),
            LevelTableRow(monthBranches: "卯午酉", companions: ["平日"], level: 3),
            LevelTableRow(monthBranches: "子", companions: ["平日", "月刑"], level: 4),
        ]),
    ]

    /// `levelDic` (lunar.py:568) keyed by `todayLevel` −1…5.
    public static func levelName(_ level: Int) -> String {
        switch level {
        case 0: return "上：吉足胜凶，从宜不从忌。"
        case 1: return "上次：吉足抵凶，遇德从宜不从忌，不遇从宜亦从忌。"
        case 2: return "中：吉不抵凶，遇德从宜不从忌，不遇从忌不从宜。"
        case 3: return "中次：凶胜于吉，遇德从宜亦从忌，不遇从忌不从宜。"
        case 4: return "下:凶又逢凶，遇德从忌不从宜，不遇诸事皆忌。"
        case 5: return "下下：凶叠大凶，遇德亦诸事皆忌。（卯酉月，灾煞遇月破、月厌，月厌遇灾煞、月破）"
        default: return "无"
        }
    }

    /// `thingLevelDic` (lunar.py:571) keyed by `thingLevel` 0…3.
    public static let thingLevelNames: [String] = ["从宜不从忌", "从宜亦从忌", "从忌不从宜", "诸事皆忌"]

    /// The six virtue names tested for `isDe` (lunar.py:574).
    public static let virtueNames: [AlmanacGodName] = [.suiDe, .suiDeHe, .yueDe, .yueDeHe, .tianDe, .tianDeHe]
}
