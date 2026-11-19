// Base activity tables ported verbatim from the pinned `config.py`:
// `officerThings` (config.py:177–204), `day8CharThing` (config.py:206–223),
// `bujiang` (config.py:172–175) and `thingsSort` (config.py:167–169).

/// Officer seeds and stem/branch additions, in upstream iteration order.
public enum UpstreamActivityTables {
    /// `officerThings[officer] = (recommend, avoid)` keyed by officer index (建…闭).
    public static let officerThings: [(recommends: [AlmanacActivity], avoids: [AlmanacActivity])] = [
        // 建 (config.py:178)
        (acts("施恩", "招贤", "举正直", "出行", "上官", "临政"), []),
        // 除 (config.py:179)
        (acts("解除", "沐浴", "整容", "剃头", "整手足甲", "求医疗病", "扫舍宇"), []),
        // 满 (config.py:180)
        (acts("进人口", "裁制", "竖柱上梁", "经络", "开市", "立券交易", "纳财", "开仓", "塞穴", "补垣"),
         acts("施恩", "招贤", "举正直", "上官", "临政", "结婚姻", "纳采", "求医疗病")),
        // 平 (config.py:182)
        (acts("修饰垣墙", "平治道涂"),
         acts("祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将",
              "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "求医疗病", "裁制", "营建", "修宫室", "缮城郭",
              "筑堤防", "修造", "竖柱上梁", "修仓库", "鼓铸", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "开渠", "穿井", "栽种",
              "牧养", "纳畜", "破土", "安葬", "启攒")),
        // 定 (config.py:187)
        (acts("冠带"), []),
        // 执 (config.py:188)
        (acts("捕捉"), []),
        // 破 (config.py:189)
        (acts("求医疗病"), []),
        // 危 (config.py:190)
        (acts("安抚边境", "选将", "安床"), []),
        // 成 (config.py:191)
        (acts("入学", "安抚边境", "搬移", "筑堤防", "开市"), []),
        // 收 (config.py:192)
        (acts("进人口", "纳财", "捕捉", "纳畜"),
         acts("祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将",
              "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "搬移", "安床", "解除", "求医疗病", "裁制", "营建", "修宫室", "缮城郭", "筑堤防", "修造",
              "竖柱上梁", "鼓铸", "经络", "酝酿", "开市", "立券交易", "开仓", "修置产室", "开渠", "穿井", "破土", "安葬", "启攒")),
        // 开 (config.py:196)
        (acts("祭祀", "祈福", "求嗣", "上册", "上表章", "颁诏", "覃恩", "施恩", "招贤", "举正直", "恤孤茕", "宣政事", "雪冤", "庆赐", "宴会", "入学",
              "出行",
              "上官", "临政", "搬移", "解除", "求医疗病", "裁制", "修宫室", "缮城郭", "修造", "修仓库", "开市", "修置产室", "开渠", "穿井", "安碓硙", "栽种",
              "牧养"), []),
        // 闭 (config.py:201)
        (acts("筑堤防", "塞穴", "补垣"),
         acts("上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "出行", "出师", "上官", "临政", "结婚姻", "纳采",
              "嫁娶", "进人口", "搬移", "安床", "求医疗病", "疗目", "营建", "修宫室", "修造", "竖柱上梁", "开市", "开仓", "修置产室", "开渠", "穿井")),
    ]

    /// `day8CharThing` (config.py:206–223) in dict insertion order; the loop tests `key in d`.
    public static let stemBranchThings: [(key: String, recommends: [AlmanacActivity], avoids: [AlmanacActivity])] = [
        ("甲", [], acts("开仓")),
        ("乙", [], acts("栽种")),
        ("丁", [], acts("整容", "剃头")),
        ("庚", [], acts("经络")),
        ("辛", [], acts("酝酿")),
        ("壬", [], acts("开渠", "穿井")),
        ("子", acts("沐浴"), []),
        ("丑", [], acts("冠带")),
        ("寅", [], acts("祭祀")),
        ("卯", [], acts("穿井")),
        ("酉", [], acts("宴会")),
        ("巳", [], acts("出行")),
        ("午", [], acts("苫盖")),
        ("未", [], acts("求医疗病")),
        ("申", [], acts("安床")),
        ("亥", acts("沐浴"), acts("嫁娶")),
    ]

    /// `bujiang` (config.py:172): 不将 pillars per rule month branch, as concatenated strings
    /// (the predicate at lunar.py:758 is a substring test on these literals).
    public static let bujiang: [String] = [
        "壬寅壬辰辛丑辛卯辛巳庚寅庚辰丁丑丁卯丁巳戊寅戊辰", "辛丑辛卯庚子庚寅庚辰丁丑丁卯丙子丙寅丙辰戊子戊寅戊辰", "辛亥辛丑辛卯庚子庚寅丁亥丁丑丁卯丙子丙寅戊子戊寅",
        "庚戌庚子庚寅丁亥丁丑丙戌丙子丙寅乙亥乙丑戊戌戊子戊寅", "丁酉丁亥丁丑丙戌丙子乙酉乙亥乙丑甲戌甲子戊戌戊子", "丁酉丁亥丙申丙戌丙子乙酉乙亥甲申甲戌甲子戊申戊戌戊子",
        "丙申丙戌乙未乙酉乙亥甲申甲戌癸未癸酉癸亥戊申戊戌", "乙未乙酉甲午甲申甲戌癸未癸酉壬午壬申壬戌戊午戊申戊戌", "乙巳乙未乙酉甲午甲申癸巳癸未癸酉壬午壬申戊午戊申",
        "甲辰甲午甲申癸巳癸未壬辰壬午壬申辛巳辛未戊辰戊午戊申", "癸卯癸巳癸未壬辰壬午辛卯辛巳辛未庚辰庚午戊辰戊午", "癸卯癸巳壬寅壬辰壬午辛卯辛巳庚寅庚辰庚午戊寅戊辰戊午",
    ]

    /// `thingsSort` (config.py:167): output collation order ("民用三十七事", 38 entries upstream).
    public static let thingsSort: [AlmanacActivity] = acts(
        "祭祀", "出行", "移徙", "结婚姻", "宴会", "嫁娶", "安床", "沐浴", "剃头", "修造", "求医疗病", "上表章", "上官", "入学", "冠带", "进人口",
        "裁衣", "竖柱上梁", "经络", "开市", "立券", "交易", "纳财", "修置产室", "开渠", "穿井", "安碓硙", "扫舍宇", "平治道涂", "破屋坏垣", "伐木", "捕捉",
        "畋猎", "栽种", "牧养", "破土", "安葬", "启攒")

    private static let collationIndex: [AlmanacActivity: Int] = {
        var out: [AlmanacActivity: Int] = [:]
        for (i, a) in thingsSort.enumerated() where out[a] == nil { out[a] = i }
        return out
    }()

    /// `sortCollation` (tools.py:25): index in `thingsSort`, else `count + 1`.
    public static func collationKey(_ activity: AlmanacActivity) -> Int {
        collationIndex[activity] ?? (thingsSort.count + 1)
    }

    /// Upstream `list.sort(key=sortCollation)` is stable; the relative order of tokens outside
    /// `thingsSort` therefore depends on Python set iteration order, which is not reproducible.
    /// The port breaks those ties deterministically by code point (documented peculiarity).
    public static func sortedForOutput(_ activities: [AlmanacActivity]) -> [AlmanacActivity] {
        activities.map { (key: collationKey($0), item: $0) }
            .sorted { a, b in a.key != b.key ? a.key < b.key : a.item < b.item }
            .map(\.item)
    }
}

/// Builds activity token arrays from upstream literals.
func acts(_ items: String...) -> [AlmanacActivity] {
    items.map(AlmanacActivity.init(_:))
}
