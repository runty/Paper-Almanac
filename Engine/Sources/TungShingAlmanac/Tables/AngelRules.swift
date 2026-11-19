// The 71 `angel` predicate tuples of the pinned `get_AngelDemon` (lunar.py:711–837),
// ported in source order. Each tuple is `(name, tuple[1], tuple[2], recommend, avoid)` and
// matches when Python evaluates `tuple[1] in tuple[2]` (lunar.py:1030): a `str` container
// means substring containment, a list/tuple container means element equality.
// Comments quote the original expressions; literals are verbatim upstream data.
// Commented-out upstream tuples (e.g. 岁德 variants at lunar.py:712/716, 鸣吠对 at 765,
// 月恩 at 780, 月空 at 807) are not rules and are not ported.

/// The `angel` table (lunar.py:711–837).
public enum UpstreamAngelRules {
    public static let rules: [GodRule] = [
        // lunar.py:714  '甲庚丙壬戊甲庚丙壬戊'[yhn] in d
        GodRule("岁德", kind: .angel, line: 714, recommends: ["修造"], avoids: []) { e in
            (needle: RuleText.at("甲庚丙壬戊甲庚丙壬戊", e.yearStemIndex), container: .text(e.dayPillar))
        },
        // lunar.py:717  '己乙辛丁癸己乙辛丁癸'[yhn] in d
        GodRule("岁德合", kind: .angel, line: 717, recommends: ["修造"], avoids: []) { e in
            (needle: RuleText.at("己乙辛丁癸己乙辛丁癸", e.yearStemIndex), container: .text(e.dayPillar))
        },
        // lunar.py:718  '壬庚丙甲壬庚丙甲壬庚丙甲'[men] in d[0]
        GodRule("月德", kind: .angel, line: 718, recommends: ["祭祀", "祈福", "求嗣", "上册", "上表章", "颁诏", "覃恩", "施恩", "招贤", "举正直", "恤孤茕", "宣政事", "雪冤", "庆赐", "宴会", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "搬移", "解除", "求医疗病", "裁制", "营建", "缮城郭", "修造", "竖柱上梁", "修仓库", "栽种", "牧养", "纳畜", "安葬"], avoids: ["畋猎", "取鱼"]) { e in
            (needle: RuleText.at("壬庚丙甲壬庚丙甲壬庚丙甲", e.monthBranchIndex), container: .text(e.dayStem))
        },
        // lunar.py:723  '丁乙辛己丁乙辛己丁乙辛己'[men] in d[0]
        GodRule("月德合", kind: .angel, line: 723, recommends: ["祭祀", "祈福", "求嗣", "上册", "上表章", "颁诏", "覃恩", "施恩", "招贤", "举正直", "恤孤茕", "宣政事", "雪冤", "庆赐", "宴会", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "搬移", "解除", "求医疗病", "裁制", "营建", "缮城郭", "修造", "竖柱上梁", "修仓库", "栽种", "牧养", "纳畜", "安葬"], avoids: ["畋猎", "取鱼"]) { e in
            (needle: RuleText.at("丁乙辛己丁乙辛己丁乙辛己", e.monthBranchIndex), container: .text(e.dayStem))
        },
        // lunar.py:735  d[1] if self.lunarMonthType == '仲' else d[0] in ['巳辰', '庚', '丁', '申未', '壬', '辛', '亥戌', '甲', '癸', '寅丑', '丙', '乙'][men]
        GodRule("天德", kind: .angel, line: 735, recommends: ["祭祀", "祈福", "求嗣", "上册", "上表章", "颁诏", "覃恩", "施恩", "招贤", "举正直", "恤孤茕", "宣政事", "雪冤", "庆赐", "宴会", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "搬移", "解除", "求医疗病", "裁制", "营建", "缮城郭", "修造", "竖柱上梁", "修仓库", "栽种", "牧养", "纳畜", "安葬"], avoids: ["畋猎", "取鱼"]) { e in
            (needle: .text(e.monthPosition == "仲" ? e.dayBranch : e.dayStem), container: .text(RuleText.pick(["巳辰", "庚", "丁", "申未", "壬", "辛", "亥戌", "甲", "癸", "寅丑", "丙", "乙"], e.monthBranchIndex)))
        },
        // lunar.py:739  '空乙壬空丁丙空己戊空辛庚'[men] in d
        GodRule("天德合", kind: .angel, line: 739, recommends: ["祭祀", "祈福", "求嗣", "上册", "上表章", "颁诏", "覃恩", "施恩", "招贤", "举正直", "恤孤茕", "宣政事", "雪冤", "庆赐", "宴会", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "搬移", "解除", "求医疗病", "裁制", "营建", "缮城郭", "修造", "竖柱上梁", "修仓库", "栽种", "牧养", "纳畜", "安葬"], avoids: ["畋猎", "取鱼"]) { e in
            (needle: RuleText.at("空乙壬空丁丙空己戊空辛庚", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:743  s[0] in '危昴胃毕'[sn]
        GodRule("凤凰日", kind: .angel, line: 743, recommends: ["嫁娶"], avoids: []) { e in
            (needle: .text(e.mansionInitial), container: .text(PyString.char("危昴胃毕", e.seasonIndex) ?? ""))
        },
        // lunar.py:744  s[0] in '井尾牛壁'[sn]
        GodRule("麒麟日", kind: .angel, line: 744, recommends: ["嫁娶"], avoids: []) { e in
            (needle: .text(e.mansionInitial), container: .text(PyString.char("井尾牛壁", e.seasonIndex) ?? ""))
        },
        // lunar.py:746  (den - men) % 4 == 0 in [True]
        GodRule("三合", kind: .angel, line: 746, recommends: ["庆赐", "宴会", "结婚姻", "纳采", "嫁娶", "进人口", "裁制", "修宫室", "缮城郭", "修造", "竖柱上梁", "修仓库", "经络", "酝酿", "立券交易", "纳财", "安碓硙", "纳畜"], avoids: []) { e in
            (needle: .boolean(floorMod(e.dayBranchIndex - e.monthBranchIndex, 4) == 0), container: .elements([.boolean(true)]))
        },
        // lunar.py:749  d[0] in ('丙丁', '戊己', '壬癸', '甲乙')[sn]
        GodRule("四相", kind: .angel, line: 749, recommends: ["祭祀", "祈福", "求嗣", "施恩", "举正直", "庆赐", "宴会", "出行", "上官", "临政", "结婚姻", "纳采", "搬移", "解除", "求医疗病", "裁制", "修宫室", "缮城郭", "修造", "竖柱上梁", "纳财", "开仓", "栽种", "牧养"], avoids: []) { e in
            (needle: .text(e.dayStem), container: .text(RuleText.pick(["丙丁", "戊己", "壬癸", "甲乙"], e.seasonIndex)))
        },
        // lunar.py:753  d[1] in '寅卯'
        GodRule("五合", kind: .angel, line: 753, recommends: ["宴会", "结婚姻", "立券交易"], avoids: []) { e in
            (needle: .text(e.dayBranch), container: .text("寅卯"))
        },
        // lunar.py:754  '巳申亥寅巳申亥寅巳申亥寅'[men] in d
        GodRule("五富", kind: .angel, line: 754, recommends: ["经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "栽种", "牧养", "纳畜"], avoids: []) { e in
            (needle: RuleText.at("巳申亥寅巳申亥寅巳申亥寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:755  '丑子亥戌酉申未午巳辰卯寅'[men] in d
        GodRule("六合", kind: .angel, line: 755, recommends: ["宴会", "结婚姻", "嫁娶", "进人口", "经络", "酝酿", "立券交易", "纳财", "纳畜", "安葬"], avoids: []) { e in
            (needle: RuleText.at("丑子亥戌酉申未午巳辰卯寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:756  '午巳辰卯寅丑子亥戌酉申未'[men] in d
        GodRule("六仪", kind: .angel, line: 756, recommends: ["临政"], avoids: []) { e in
            (needle: RuleText.at("午巳辰卯寅丑子亥戌酉申未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:758  d in bujiang[men]
        GodRule("不将", kind: .angel, line: 758, recommends: ["嫁娶"], avoids: []) { e in
            (needle: .text(e.dayPillar), container: .text(RuleText.pick(UpstreamActivityTables.bujiang, e.monthBranchIndex)))
        },
        // lunar.py:759  '午辰子寅'[sn] in d[1]
        GodRule("时德", kind: .angel, line: 759, recommends: ["祭祀", "祈福", "求嗣", "施恩", "举正直", "庆赐", "宴会", "出行", "上官", "临政", "结婚姻", "纳采", "搬移", "解除", "求医疗病", "裁制", "修宫室", "缮城郭", "修造", "竖柱上梁", "纳财", "开仓", "栽种", "牧养"], avoids: []) { e in
            (needle: RuleText.at("午辰子寅", e.seasonIndex), container: .text(e.dayBranch))
        },
        // lunar.py:762  d in '壬申癸酉壬午甲申乙酉丙申丁酉壬寅丙午己酉庚申辛酉'
        GodRule("大葬", kind: .angel, line: 762, recommends: ["安葬"], avoids: []) { e in
            (needle: .text(e.dayPillar), container: .text("壬申癸酉壬午甲申乙酉丙申丁酉壬寅丙午己酉庚申辛酉"))
        },
        // lunar.py:763  d in '庚午壬申癸酉壬午甲申乙酉己酉丙申丁酉壬寅丙午庚寅庚申辛酉'
        GodRule("鸣吠", kind: .angel, line: 763, recommends: ["破土", "安葬"], avoids: []) { e in
            (needle: .text(e.dayPillar), container: .text("庚午壬申癸酉壬午甲申乙酉己酉丙申丁酉壬寅丙午庚寅庚申辛酉"))
        },
        // lunar.py:764  d in '庚午壬辰甲辰乙巳甲寅丙辰庚寅'
        GodRule("小葬", kind: .angel, line: 764, recommends: ["安葬"], avoids: []) { e in
            (needle: .text(e.dayPillar), container: .text("庚午壬辰甲辰乙巳甲寅丙辰庚寅"))
        },
        // lunar.py:766  d in '丙寅丁卯丙子辛卯甲午庚子癸卯壬子甲寅乙卯'
        GodRule("鸣吠对", kind: .angel, line: 766, recommends: ["破土", "启攒"], avoids: []) { e in
            (needle: .text(e.dayPillar), container: .text("丙寅丁卯丙子辛卯甲午庚子癸卯壬子甲寅乙卯"))
        },
        // lunar.py:767  d in '庚午辛未壬申癸酉戊寅己卯壬午癸未甲申乙酉丁未甲午乙未丙申丁酉壬寅癸卯丙午戊申己酉庚申辛酉'
        GodRule("不守塚", kind: .angel, line: 767, recommends: ["破土"], avoids: []) { e in
            (needle: .text(e.dayPillar), container: .text("庚午辛未壬申癸酉戊寅己卯壬午癸未甲申乙酉丁未甲午乙未丙申丁酉壬寅癸卯丙午戊申己酉庚申辛酉"))
        },
        // lunar.py:769  '寅巳申亥'[sn] in d[1]
        GodRule("王日", kind: .angel, line: 769, recommends: ["颁诏", "覃恩", "施恩", "招贤", "举正直", "恤孤茕", "宣政事", "雪冤", "庆赐", "宴会", "出行", "安抚边境", "选将", "上官", "临政", "裁制"], avoids: []) { e in
            (needle: RuleText.at("寅巳申亥", e.seasonIndex), container: .text(e.dayBranch))
        },
        // lunar.py:771  '卯午酉子'[sn] in d[1]
        GodRule("官日", kind: .angel, line: 771, recommends: ["上官", "临政"], avoids: []) { e in
            (needle: RuleText.at("卯午酉子", e.seasonIndex), container: .text(e.dayBranch))
        },
        // lunar.py:772  '酉子卯午'[sn] in d[1]
        GodRule("守日", kind: .angel, line: 772, recommends: ["安抚边境", "上官", "临政"], avoids: []) { e in
            (needle: RuleText.at("酉子卯午", e.seasonIndex), container: .text(e.dayBranch))
        },
        // lunar.py:773  '巳申亥寅'[sn] in d[1]
        GodRule("相日", kind: .angel, line: 773, recommends: ["上官", "临政"], avoids: []) { e in
            (needle: RuleText.at("巳申亥寅", e.seasonIndex), container: .text(e.dayBranch))
        },
        // lunar.py:774  '午酉子卯'[sn] in d[1]
        GodRule("民日", kind: .angel, line: 774, recommends: ["宴会", "结婚姻", "纳采", "进人口", "搬移", "开市", "立券交易", "纳财", "栽种", "牧养", "纳畜"], avoids: []) { e in
            (needle: RuleText.at("午酉子卯", e.seasonIndex), container: .text(e.dayBranch))
        },
        // lunar.py:775  '辰酉午亥申丑戌卯子巳寅未'[men] in d
        GodRule("临日", kind: .angel, line: 775, recommends: ["上册", "上表章", "上官", "临政"], avoids: []) { e in
            (needle: RuleText.at("辰酉午亥申丑戌卯子巳寅未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:776  d[0] in ('甲乙', '丙丁', '庚辛', '壬癸')[sn]
        GodRule("天贵", kind: .angel, line: 776, recommends: [], avoids: []) { e in
            (needle: .text(e.dayStem), container: .text(RuleText.pick(["甲乙", "丙丁", "庚辛", "壬癸"], e.seasonIndex)))
        },
        // lunar.py:777  '申酉戌亥子丑寅卯辰巳午未'[men] in d[1]
        GodRule("天喜", kind: .angel, line: 777, recommends: ["施恩", "举正直", "庆赐", "宴会", "出行", "上官", "临政", "结婚姻", "纳采", "嫁娶"], avoids: []) { e in
            (needle: RuleText.at("申酉戌亥子丑寅卯辰巳午未", e.monthBranchIndex), container: .text(e.dayBranch))
        },
        // lunar.py:778  '寅卯辰巳午未申酉戌亥子丑'[men] in d
        GodRule("天富", kind: .angel, line: 778, recommends: ["安葬", "修仓库"], avoids: []) { e in
            (needle: RuleText.at("寅卯辰巳午未申酉戌亥子丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:779  dhen % 15 < 5 and dhen // 15 != 2 in [True]
        GodRule("天恩", kind: .angel, line: 779, recommends: ["覃恩", "恤孤茕", "布政事", "雪冤", "庆赐", "宴会"], avoids: []) { e in
            (needle: .boolean(e.daySexagenaryIndex % 15 < 5 && e.daySexagenaryIndex / 15 != 2), container: .elements([.boolean(true)]))
        },
        // lunar.py:781  '甲辛丙丁庚己戊辛壬癸庚乙'[men] in d
        GodRule("月恩", kind: .angel, line: 781, recommends: ["祭祀", "祈福", "求嗣", "施恩", "举正直", "庆赐", "宴会", "出行", "上官", "临政", "结婚姻", "纳采", "搬移", "解除", "求医疗病", "裁制", "修宫室", "缮城郭", "修造", "竖柱上梁", "纳财", "开仓", "栽种", "牧养"], avoids: []) { e in
            (needle: RuleText.at("甲辛丙丁庚己戊辛壬癸庚乙", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:784  ['甲子', '甲子', '戊寅', '戊寅', '戊寅', '甲午', '甲午', '甲午', '戊申', '戊申', '戊申', '甲子'][men] in d
        GodRule("天赦", kind: .angel, line: 784, recommends: ["祭祀", "祈福", "求嗣", "上册", "上表章", "颁诏", "覃恩", "施恩", "招贤", "举正直", "恤孤茕", "宣政事", "雪冤", "庆赐", "宴会", "出行", "安抚边境", "选将", "上官", "临政", "结婚姻", "纳采", "嫁娶", "搬移", "解除", "求医疗病", "裁制", "营建", "缮城郭", "修造", "竖柱上梁", "修仓库", "栽种", "牧养", "纳畜", "安葬"], avoids: ["畋猎", "取鱼"]) { e in
            (needle: .text(RuleText.pick(["甲子", "甲子", "戊寅", "戊寅", "戊寅", "甲午", "甲午", "甲午", "戊申", "戊申", "戊申", "甲子"], e.monthBranchIndex)), container: .text(e.dayPillar))
        },
        // lunar.py:790  ['癸丑', '甲子', '乙亥', '甲戌', '乙酉', '丙申', '丁未', '戊午', '己巳', '庚辰', '辛卯', '壬寅'][men] in d
        GodRule("天愿", kind: .angel, line: 790, recommends: ["祭祀", "祈福", "求嗣", "上册", "上表章", "颁诏", "覃恩", "施恩", "招贤", "举正直", "恤孤茕", "宣政事", "雪冤", "庆赐", "宴会", "出行", "安抚边境", "选将", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "裁制", "营建", "缮城郭", "修造", "竖柱上梁", "修仓库", "经络", "酝酿", "开市", "立券交易", "纳财", "栽种", "牧养", "纳畜", "安葬"], avoids: []) { e in
            (needle: .text(RuleText.pick(["癸丑", "甲子", "乙亥", "甲戌", "乙酉", "丙申", "丁未", "戊午", "己巳", "庚辰", "辛卯", "壬寅"], e.monthBranchIndex)), container: .text(e.dayPillar))
        },
        // lunar.py:794  '卯巳未酉亥丑卯巳未酉亥丑'[men] in d
        GodRule("天成", kind: .angel, line: 794, recommends: [], avoids: []) { e in
            (needle: RuleText.at("卯巳未酉亥丑卯巳未酉亥丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:795  '午申戌子寅辰午申戌子寅辰'[men] in d
        GodRule("天官", kind: .angel, line: 795, recommends: [], avoids: []) { e in
            (needle: RuleText.at("午申戌子寅辰午申戌子寅辰", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:796  '亥子丑寅卯辰巳午未申酉戌'[men] in d
        GodRule("天医", kind: .angel, line: 796, recommends: ["求医疗病"], avoids: []) { e in
            (needle: RuleText.at("亥子丑寅卯辰巳午未申酉戌", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:797  '寅辰午申戌子寅辰午申戌子'[men] in d
        GodRule("天马", kind: .angel, line: 797, recommends: ["出行", "搬移"], avoids: []) { e in
            (needle: RuleText.at("寅辰午申戌子寅辰午申戌子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:798  '寅亥申巳寅亥申巳寅亥申巳'[men] in d
        GodRule("驿马", kind: .angel, line: 798, recommends: ["出行", "搬移"], avoids: []) { e in
            (needle: RuleText.at("寅亥申巳寅亥申巳寅亥申巳", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:799  '子寅辰午申戌子寅辰午申戌'[men] in d
        GodRule("天财", kind: .angel, line: 799, recommends: [], avoids: []) { e in
            (needle: RuleText.at("子寅辰午申戌子寅辰午申戌", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:800  '寅申酉卯戌辰亥巳子午丑未'[men] in d
        GodRule("福生", kind: .angel, line: 800, recommends: ["祭祀", "祈福"], avoids: []) { e in
            (needle: RuleText.at("寅申酉卯戌辰亥巳子午丑未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:801  '寅巳申亥'[sn] in d
        GodRule("福厚", kind: .angel, line: 801, recommends: [], avoids: []) { e in
            (needle: RuleText.at("寅巳申亥", e.seasonIndex), container: .text(e.dayPillar))
        },
        // lunar.py:802  '寅卯辰巳午未申酉戌亥子丑'[men] in d
        GodRule("福德", kind: .angel, line: 802, recommends: ["上册", "上表章", "庆赐", "宴会", "修宫室", "缮城郭"], avoids: []) { e in
            (needle: RuleText.at("寅卯辰巳午未申酉戌亥子丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:803  '寅卯辰巳午未申酉戌亥子丑'[men] in d
        GodRule("天巫", kind: .angel, line: 803, recommends: ["求医疗病"], avoids: []) { e in
            (needle: RuleText.at("寅卯辰巳午未申酉戌亥子丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:805  '丑卯巳未酉亥丑卯巳未酉亥'[men] in d
        GodRule("地财", kind: .angel, line: 805, recommends: [], avoids: []) { e in
            (needle: RuleText.at("丑卯巳未酉亥丑卯巳未酉亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:806  '酉亥午巳巳未酉亥午巳巳未'[men] in d
        GodRule("月财", kind: .angel, line: 806, recommends: [], avoids: []) { e in
            (needle: RuleText.at("酉亥午巳巳未酉亥午巳巳未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:808  '丙甲壬庚丙甲壬庚丙甲壬庚'[men] in d
        GodRule("月空", kind: .angel, line: 808, recommends: ["上表章"], avoids: []) { e in
            (needle: RuleText.at("丙甲壬庚丙甲壬庚丙甲壬庚", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:809  d[1] in ('亥子', '寅卯', '辰丑戌未', '申酉')[sn]
        GodRule("母仓", kind: .angel, line: 809, recommends: ["纳财", "栽种", "牧养", "纳畜"], avoids: []) { e in
            (needle: .text(e.dayBranch), container: .text(RuleText.pick(["亥子", "寅卯", "辰丑戌未", "申酉"], e.seasonIndex)))
        },
        // lunar.py:810  '辰午甲戌子寅辰午甲戌子寅'[men] in d
        GodRule("明星", kind: .angel, line: 810, recommends: ["赴任", "诉讼", "安葬"], avoids: []) { e in
            (needle: RuleText.at("辰午甲戌子寅辰午甲戌子寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:811  '辰戌亥巳子午丑未寅申卯酉'[men] in d
        GodRule("圣心", kind: .angel, line: 811, recommends: ["祭祀", "祈福"], avoids: []) { e in
            (needle: RuleText.at("辰戌亥巳子午丑未寅申卯酉", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:812  '寅卯辰巳午未申酉戌亥子丑'[men] in d
        GodRule("禄库", kind: .angel, line: 812, recommends: ["纳财"], avoids: []) { e in
            (needle: RuleText.at("寅卯辰巳午未申酉戌亥子丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:814  '未子酉寅亥辰丑午卯申巳戌'[men] in d
        GodRule("吉庆", kind: .angel, line: 814, recommends: [], avoids: []) { e in
            (needle: RuleText.at("未子酉寅亥辰丑午卯申巳戌", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:815  '丑亥酉未巳卯丑亥酉未巳卯'[men] in d
        GodRule("阴德", kind: .angel, line: 815, recommends: ["恤孤茕", "雪冤"], avoids: []) { e in
            (needle: RuleText.at("丑亥酉未巳卯丑亥酉未巳卯", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:816  '卯申巳戌未子酉寅亥辰丑午'[men] in d
        GodRule("活曜", kind: .angel, line: 816, recommends: [], avoids: []) { e in
            (needle: RuleText.at("卯申巳戌未子酉寅亥辰丑午", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:817  d[1] in '申酉'
        GodRule("除神", kind: .angel, line: 817, recommends: ["解除", "沐浴", "整容", "剃头", "整手足甲", "求医疗病", "扫舍宇"], avoids: []) { e in
            (needle: .text(e.dayBranch), container: .text("申酉"))
        },
        // lunar.py:818  '午午申申戌戌子子寅寅辰辰'[men] in d
        GodRule("解神", kind: .angel, line: 818, recommends: ["上表章", "解除", "沐浴", "整容", "剃头", "整手足甲", "求医疗病"], avoids: []) { e in
            (needle: RuleText.at("午午申申戌戌子子寅寅辰辰", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:819  '戌亥子丑寅卯辰巳午未申酉'[men] in d
        GodRule("生气", kind: .angel, line: 819, recommends: [], avoids: ["伐木", "畋猎", "取鱼"]) { e in
            (needle: RuleText.at("戌亥子丑寅卯辰巳午未申酉", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:820  '丑卯申寅酉卯戌辰亥巳子午'[men] in d
        GodRule("普护", kind: .angel, line: 820, recommends: ["祭祀", "祈福"], avoids: []) { e in
            (needle: RuleText.at("丑卯申寅酉卯戌辰亥巳子午", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:821  '巳亥子午丑未寅申卯酉辰戌'[men] in d
        GodRule("益后", kind: .angel, line: 821, recommends: ["祭祀", "祈福", "求嗣"], avoids: []) { e in
            (needle: RuleText.at("巳亥子午丑未寅申卯酉辰戌", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:822  '午子丑未寅申卯酉辰戌巳亥'[men] in d
        GodRule("续世", kind: .angel, line: 822, recommends: ["祭祀", "祈福", "求嗣"], avoids: []) { e in
            (needle: RuleText.at("午子丑未寅申卯酉辰戌巳亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:823  '未丑寅申卯酉辰戌巳亥午子'[men] in d
        GodRule("要安", kind: .angel, line: 823, recommends: [], avoids: []) { e in
            (needle: RuleText.at("未丑寅申卯酉辰戌巳亥午子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:824  '寅亥申巳寅亥申巳寅亥申巳'[men] in d
        GodRule("天后", kind: .angel, line: 824, recommends: ["求医疗病"], avoids: []) { e in
            (needle: RuleText.at("寅亥申巳寅亥申巳寅亥申巳", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:825  '辰卯寅丑子亥戌酉申未午巳'[men] in d
        GodRule("天仓", kind: .angel, line: 825, recommends: ["进人口", "纳财", "纳畜"], avoids: []) { e in
            (needle: RuleText.at("辰卯寅丑子亥戌酉申未午巳", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:827  '子午未丑申寅酉卯戌辰亥巳'[men] in d
        GodRule("敬安", kind: .angel, line: 827, recommends: [], avoids: []) { e in
            (needle: RuleText.at("子午未丑申寅酉卯戌辰亥巳", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:828  '申寅卯酉辰戌巳亥午子未丑'[men] in d
        GodRule("玉宇", kind: .angel, line: 828, recommends: [], avoids: []) { e in
            (needle: RuleText.at("申寅卯酉辰戌巳亥午子未丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:829  '酉卯辰戌巳亥午子未丑申寅'[men] in d
        GodRule("金堂", kind: .angel, line: 829, recommends: [], avoids: []) { e in
            (needle: RuleText.at("酉卯辰戌巳亥午子未丑申寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:830  '丑寅卯辰巳午未申酉戌亥子'[men] in d
        GodRule("吉期", kind: .angel, line: 830, recommends: ["施恩", "举正直", "出行", "上官", "临政"], avoids: []) { e in
            (needle: RuleText.at("丑寅卯辰巳午未申酉戌亥子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:831  '子丑寅卯辰巳午未申酉戌亥'[men] in d
        GodRule("小时", kind: .angel, line: 831, recommends: [], avoids: []) { e in
            (needle: RuleText.at("子丑寅卯辰巳午未申酉戌亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:832  '子丑寅卯辰巳午未申酉戌亥'[men] in d
        GodRule("兵福", kind: .angel, line: 832, recommends: ["安抚边境", "选将", "出师"], avoids: []) { e in
            (needle: RuleText.at("子丑寅卯辰巳午未申酉戌亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:833  '丑寅卯辰巳午未申酉戌亥子'[men] in d
        GodRule("兵宝", kind: .angel, line: 833, recommends: ["安抚边境", "选将", "出师"], avoids: []) { e in
            (needle: RuleText.at("丑寅卯辰巳午未申酉戌亥子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:834  d[1] in ['寅卯辰巳', '丑寅卯辰', '子丑寅卯', '亥子丑寅', '戌亥子丑', '酉戌亥子', '申酉戌亥', '未申酉戌', '午未申酉', '巳午未申', '辰巳午未', '卯辰巳午'][men]
        GodRule("兵吉", kind: .angel, line: 834, recommends: ["安抚边境", "选将", "出师"], avoids: []) { e in
            (needle: .text(e.dayBranch), container: .text(RuleText.pick(["寅卯辰巳", "丑寅卯辰", "子丑寅卯", "亥子丑寅", "戌亥子丑", "酉戌亥子", "申酉戌亥", "未申酉戌", "午未申酉", "巳午未申", "辰巳午未", "卯辰巳午"], e.monthBranchIndex)))
        },
    ]
}
