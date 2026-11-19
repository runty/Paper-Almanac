// The 100 `demon` predicate tuples of the pinned `get_AngelDemon` (lunar.py:838–1018),
// ported in source order with the same membership semantics as `UpstreamAngelRules`.
// Commented-out upstream tuples (勾绞 at lunar.py:844, 人隔 at 890, 冰消瓦陷 at 900,
// 四正废 at 950) are not rules and are not ported.

/// The `demon` table (lunar.py:838–1018).
public enum UpstreamDemonRules {
    public static let rules: [GodRule] = [
        // lunar.py:839  den == (yen + 6) % 12 in [True]
        GodRule("岁破", kind: .demon, line: 839, recommends: [], avoids: ["修造", "搬移", "嫁娶", "出行"]) { e in
            (needle: .boolean(e.dayBranchIndex == (e.yearBranchIndex + 6) % 12), container: .elements([.boolean(true)]))
        },
        // lunar.py:841  '卯戌巳子未寅酉辰亥午丑申'[men] in d
        GodRule("天罡", kind: .demon, line: 841, recommends: [], avoids: ["安葬"]) { e in
            (needle: RuleText.at("卯戌巳子未寅酉辰亥午丑申", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:842  '酉辰亥午丑申卯戌巳子未寅'[men] in d
        GodRule("河魁", kind: .demon, line: 842, recommends: [], avoids: ["安葬"]) { e in
            (needle: RuleText.at("酉辰亥午丑申卯戌巳子未寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:843  '卯辰巳午未申酉戌亥子丑寅'[men] in d
        GodRule("死神", kind: .demon, line: 843, recommends: [], avoids: ["安抚边境", "选将", "出师", "进人口", "解除", "求医疗病", "修置产室", "栽种", "牧养", "纳畜"]) { e in
            (needle: RuleText.at("卯辰巳午未申酉戌亥子丑寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:845  '辰巳午未申酉戌亥子丑寅卯'[men] in d
        GodRule("死气", kind: .demon, line: 845, recommends: [], avoids: ["安抚边境", "选将", "出师", "解除", "求医疗病", "修置产室", "栽种"]) { e in
            (needle: RuleText.at("辰巳午未申酉戌亥子丑寅卯", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:846  '丙甲壬庚'[yen % 4] in d[0]
        GodRule("伏兵", kind: .demon, line: 846, recommends: [], avoids: ["修仓库", "修造", "出师"]) { e in
            (needle: RuleText.at("丙甲壬庚", e.yearBranchIndex % 4), container: .text(e.dayStem))
        },
        // lunar.py:848  '辰巳午未申酉戌亥子丑寅卯'[men] in d
        GodRule("官符", kind: .demon, line: 848, recommends: [], avoids: ["上表章", "上册"]) { e in
            (needle: RuleText.at("辰巳午未申酉戌亥子丑寅卯", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:849  '子丑寅卯辰巳午未申酉戌亥'[men] in d
        GodRule("月建", kind: .demon, line: 849, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "结婚姻", "纳采", "解除", "整容", "剃头", "整手足甲", "求医疗病", "营建", "修宫室", "缮城郭", "修造", "竖柱上梁", "修仓库", "开仓", "修置产室", "破屋坏垣", "伐木", "栽种", "破土", "安葬", "启攒"]) { e in
            (needle: RuleText.at("子丑寅卯辰巳午未申酉戌亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:852  '午未申酉戌亥子丑寅卯辰巳'[men] in d
        GodRule("月破", kind: .demon, line: 852, recommends: ["破屋坏垣"], avoids: ["祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "整容", "剃头", "整手足甲", "裁制", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "鼓铸", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "开渠", "穿井", "安碓硙", "塞穴", "补垣", "修饰垣墙", "伐木", "栽种", "牧养", "纳畜", "破土", "安葬", "启攒"]) { e in
            (needle: RuleText.at("午未申酉戌亥子丑寅卯辰巳", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:857  '未辰丑戌未辰丑戌未辰丑戌'[men] in d
        GodRule("月煞", kind: .demon, line: 857, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "整容", "剃头", "整手足甲", "求医疗病", "裁制", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "鼓铸", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "开渠", "穿井", "安碓硙", "塞穴", "补垣", "修饰垣墙", "破屋坏垣", "栽种", "牧养", "纳畜", "安葬"]) { e in
            (needle: RuleText.at("未辰丑戌未辰丑戌未辰丑戌", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:862  '未午巳辰卯寅丑子亥戌酉申'[men] in d
        GodRule("月害", kind: .demon, line: 862, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "庆赐", "宴会", "安抚边境", "选将", "出师", "上官", "纳采", "嫁娶", "进人口", "求医疗病", "修仓库", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "牧养", "纳畜", "破土", "安葬", "启攒"]) { e in
            (needle: RuleText.at("未午巳辰卯寅丑子亥戌酉申", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:865  '卯戌巳子辰申午丑寅酉未亥'[men] in d
        GodRule("月刑", kind: .demon, line: 865, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "整容", "剃头", "整手足甲", "求医疗病", "裁制", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "鼓铸", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "开渠", "穿井", "安碓硙", "塞穴", "补垣", "修饰垣墙", "破屋坏垣", "栽种", "牧养", "纳畜", "破土", "安葬", "启攒"]) { e in
            (needle: RuleText.at("卯戌巳子辰申午丑寅酉未亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:870  '子亥戌酉申未午巳辰卯寅丑'[men] in d
        GodRule("月厌", kind: .demon, line: 870, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "远回", "安床", "解除", "整容", "剃头", "整手足甲", "求医疗病", "裁制", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "鼓铸", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "开渠", "穿井", "安碓硙", "塞穴", "补垣", "修饰垣墙", "平治道涂", "破屋坏垣", "伐木", "栽种", "牧养", "纳畜", "破土", "安葬", "启攒"]) { e in
            (needle: RuleText.at("子亥戌酉申未午巳辰卯寅丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:875  ldn in (5, 14, 23)
        GodRule("月忌", kind: .demon, line: 875, recommends: [], avoids: ["出行", "乘船渡水"]) { e in
            (needle: .integer(e.lunarDay), container: .elements([.integer(5), .integer(14), .integer(23)]))
        },
        // lunar.py:876  '未辰丑戌未辰丑戌未辰丑戌'[men] in d
        GodRule("月虚", kind: .demon, line: 876, recommends: [], avoids: ["修仓库", "纳财", "开仓"]) { e in
            (needle: RuleText.at("未辰丑戌未辰丑戌未辰丑戌", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:877  '午卯子酉午卯子酉午卯子酉'[men] in d
        GodRule("灾煞", kind: .demon, line: 877, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "整容", "剃头", "整手足甲", "求医疗病", "裁制", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "鼓铸", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "开渠", "穿井", "安碓硙", "塞穴", "补垣", "修饰垣墙", "破屋坏垣", "栽种", "牧养", "纳畜", "破土", "安葬", "启攒"]) { e in
            (needle: RuleText.at("午卯子酉午卯子酉午卯子酉", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:882  '巳寅亥申巳寅亥申巳寅亥申'[men] in d
        GodRule("劫煞", kind: .demon, line: 882, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "整容", "剃头", "整手足甲", "求医疗病", "裁制", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "鼓铸", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "开渠", "穿井", "安碓硙", "塞穴", "补垣", "修饰垣墙", "破屋坏垣", "栽种", "牧养", "纳畜", "破土", "安葬", "启攒"]) { e in
            (needle: RuleText.at("巳寅亥申巳寅亥申巳寅亥申", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:887  '午巳辰卯寅丑子亥戌酉申未'[men] in d
        GodRule("厌对", kind: .demon, line: 887, recommends: [], avoids: ["嫁娶"]) { e in
            (needle: RuleText.at("午巳辰卯寅丑子亥戌酉申未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:888  '午巳辰卯寅丑子亥戌酉申未'[men] in d
        GodRule("招摇", kind: .demon, line: 888, recommends: [], avoids: ["取鱼", "乘船渡水"]) { e in
            (needle: RuleText.at("午巳辰卯寅丑子亥戌酉申未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:889  '酉丑巳酉丑巳酉丑巳酉丑巳'[men] in d
        GodRule("小红砂", kind: .demon, line: 889, recommends: [], avoids: ["嫁娶"]) { e in
            (needle: RuleText.at("酉丑巳酉丑巳酉丑巳酉丑巳", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:891  '戌丑寅巳申亥卯午酉子辰未'[men] in d
        GodRule("往亡", kind: .demon, line: 891, recommends: [], avoids: ["上册", "上表章", "颁诏", "招贤", "宣政事", "出行", "安抚边境", "选将", "出师", "上官", "临政", "嫁娶", "进人口", "搬移", "求医疗病", "捕捉", "畋猎", "取鱼"]) { e in
            (needle: RuleText.at("戌丑寅巳申亥卯午酉子辰未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:894  '癸己甲乙己丙丁己庚辛己壬'[men] in d
        GodRule("重丧", kind: .demon, line: 894, recommends: [], avoids: ["嫁娶", "安葬"]) { e in
            (needle: RuleText.at("癸己甲乙己丙丁己庚辛己壬", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:895  '癸己庚辛己壬癸戊甲乙己壬'[men] in d
        GodRule("重复", kind: .demon, line: 895, recommends: [], avoids: ["嫁娶", "安葬"]) { e in
            (needle: RuleText.at("癸己庚辛己壬癸戊甲乙己壬", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:896  (lmn, ldn) in mrY13
        GodRule("杨公忌", kind: .demon, line: 896, recommends: [], avoids: ["开张", "修造", "嫁娶", "立券"]) { e in
            (needle: .monthDay(month: e.lunarMonth, day: e.lunarDay), container: .elements(UpstreamRuleConstants.yangGongTaboos))
        },
        // lunar.py:897  '申酉戌亥子丑寅卯辰巳午未'[men] in d
        GodRule("神号", kind: .demon, line: 897, recommends: [], avoids: []) { e in
            (needle: RuleText.at("申酉戌亥子丑寅卯辰巳午未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:898  '辰辰午午申申戌戌子子寅寅'[men] in d
        GodRule("妨择", kind: .demon, line: 898, recommends: [], avoids: []) { e in
            (needle: RuleText.at("辰辰午午申申戌戌子子寅寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:899  '午卯子酉午卯子酉午卯子酉'[men] in d
        GodRule("披麻", kind: .demon, line: 899, recommends: [], avoids: ["嫁娶", "入宅"]) { e in
            (needle: RuleText.at("午卯子酉午卯子酉午卯子酉", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:902  '午未申酉戌亥子丑寅卯辰巳'[men] in d
        GodRule("大耗", kind: .demon, line: 902, recommends: [], avoids: ["修仓库", "开市", "立券交易", "纳财", "开仓"]) { e in
            (needle: RuleText.at("午未申酉戌亥子丑寅卯辰巳", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:904  '丁乙癸辛'[yen % 4] in d[0]
        GodRule("大祸", kind: .demon, line: 904, recommends: [], avoids: ["修仓库", "修造", "出师"]) { e in
            (needle: RuleText.at("丁乙癸辛", e.yearBranchIndex % 4), container: .text(e.dayStem))
        },
        // lunar.py:905  '卯子酉午卯子酉午卯子酉午'[men] in d
        GodRule("天吏", kind: .demon, line: 905, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "施恩", "招贤", "举正直", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "求医疗病", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "开市", "立券交易", "纳财", "开仓", "修置产室", "栽种", "牧养", "纳畜"]) { e in
            (needle: RuleText.at("卯子酉午卯子酉午卯子酉午", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:909  '丑卯未戌辰寅午子酉申巳亥'[men] in d
        GodRule("天瘟", kind: .demon, line: 909, recommends: [], avoids: ["修造", "求医疗病", "纳畜"]) { e in
            (needle: RuleText.at("丑卯未戌辰寅午子酉申巳亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:910  '午酉子卯午酉子卯午酉子卯'[men] in d
        GodRule("天狱", kind: .demon, line: 910, recommends: [], avoids: []) { e in
            (needle: RuleText.at("午酉子卯午酉子卯午酉子卯", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:911  '午酉子卯午酉子卯午酉子卯'[men] in d
        GodRule("天火", kind: .demon, line: 911, recommends: [], avoids: ["苫盖"]) { e in
            (needle: RuleText.at("午酉子卯午酉子卯午酉子卯", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:912  '寅辰午申戌子寅辰午申戌子'[men] in d
        GodRule("天棒", kind: .demon, line: 912, recommends: [], avoids: []) { e in
            (needle: RuleText.at("寅辰午申戌子寅辰午申戌子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:913  '寅卯辰巳午未申酉戌亥子丑'[men] in d
        GodRule("天狗", kind: .demon, line: 913, recommends: [], avoids: ["祭祀"]) { e in
            (needle: RuleText.at("寅卯辰巳午未申酉戌亥子丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:914  '戌亥子丑寅卯辰巳午未申酉'[men] in d
        GodRule("天狗下食", kind: .demon, line: 914, recommends: [], avoids: ["祭祀"]) { e in
            (needle: RuleText.at("戌亥子丑寅卯辰巳午未申酉", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:915  '卯寅丑子亥戌酉申未午巳辰'[men] in d
        GodRule("天贼", kind: .demon, line: 915, recommends: [], avoids: ["出行", "修仓库", "开仓"]) { e in
            (needle: RuleText.at("卯寅丑子亥戌酉申未午巳辰", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:916  d in ['辛未辛酉', '乙酉乙未', '庚子庚午', '癸未癸丑', '甲子甲寅', '己卯己丑', '戊辰戊午', '癸未癸巳', '丙寅丙申', '丁卯丁巳', '戊辰戊子', '庚戌庚子'][men]
        GodRule("地囊", kind: .demon, line: 916, recommends: [], avoids: ["营建", "修宫室", "缮城郭", "筑堤防", "修造", "修仓库", "修置产室", "开渠", "穿井", "安碓硙", "补垣", "修饰垣墙", "平治道涂", "破屋坏垣", "栽种", "破土"]) { e in
            (needle: .text(e.dayPillar), container: .text(RuleText.pick(["辛未辛酉", "乙酉乙未", "庚子庚午", "癸未癸丑", "甲子甲寅", "己卯己丑", "戊辰戊午", "癸未癸巳", "丙寅丙申", "丁卯丁巳", "戊辰戊子", "庚戌庚子"], e.monthBranchIndex)))
        },
        // lunar.py:920  '子亥戌酉申未午巳辰卯寅丑'[men] in d
        GodRule("地火", kind: .demon, line: 920, recommends: [], avoids: ["栽种"]) { e in
            (needle: RuleText.at("子亥戌酉申未午巳辰卯寅丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:921  '未午巳辰卯寅丑子亥戌酉申'[men] in d
        GodRule("独火", kind: .demon, line: 921, recommends: [], avoids: ["修造"]) { e in
            (needle: RuleText.at("未午巳辰卯寅丑子亥戌酉申", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:922  '卯酉戌辰亥巳子午丑未寅申'[men] in d
        GodRule("受死", kind: .demon, line: 922, recommends: [], avoids: ["畋猎"]) { e in
            (needle: RuleText.at("卯酉戌辰亥巳子午丑未寅申", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:923  '寅子午寅子午寅子午寅子午'[men] in d
        GodRule("黄沙", kind: .demon, line: 923, recommends: [], avoids: ["出行"]) { e in
            (needle: RuleText.at("寅子午寅子午寅子午寅子午", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:924  '卯未寅午戌巳酉丑申子辰亥'[men] in d
        GodRule("六不成", kind: .demon, line: 924, recommends: [], avoids: ["修造"]) { e in
            (needle: RuleText.at("卯未寅午戌巳酉丑申子辰亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:926  '巳午未申酉戌亥子丑寅卯辰'[men] in d
        GodRule("小耗", kind: .demon, line: 926, recommends: [], avoids: ["修仓库", "开市", "立券交易", "纳财", "开仓"]) { e in
            (needle: RuleText.at("巳午未申酉戌亥子丑寅卯辰", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:927  '酉未巳卯丑亥酉未巳卯丑亥'[men] in d
        GodRule("神隔", kind: .demon, line: 927, recommends: [], avoids: ["祭祀", "祈福"]) { e in
            (needle: RuleText.at("酉未巳卯丑亥酉未巳卯丑亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:928  '亥丑卯巳未酉亥丑卯巳未酉'[men] in d
        GodRule("朱雀", kind: .demon, line: 928, recommends: [], avoids: ["嫁娶"]) { e in
            (needle: RuleText.at("亥丑卯巳未酉亥丑卯巳未酉", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:929  '寅辰午申戌子寅辰午申戌子'[men] in d
        GodRule("白虎", kind: .demon, line: 929, recommends: [], avoids: ["安葬"]) { e in
            (needle: RuleText.at("寅辰午申戌子寅辰午申戌子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:930  '巳未酉亥丑卯巳未酉亥丑卯'[men] in d
        GodRule("玄武", kind: .demon, line: 930, recommends: [], avoids: ["安葬"]) { e in
            (needle: RuleText.at("巳未酉亥丑卯巳未酉亥丑卯", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:931  '未酉亥丑卯巳未酉亥丑卯巳'[men] in d
        GodRule("勾陈", kind: .demon, line: 931, recommends: [], avoids: []) { e in
            (needle: RuleText.at("未酉亥丑卯巳未酉亥丑卯巳", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:932  '辰午巳未酉申戌子亥丑卯寅'[men] in d
        GodRule("木马", kind: .demon, line: 932, recommends: [], avoids: []) { e in
            (needle: RuleText.at("辰午巳未酉申戌子亥丑卯寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:933  '辰午申戌子寅辰午申戌子寅'[men] in d
        GodRule("破败", kind: .demon, line: 933, recommends: [], avoids: []) { e in
            (needle: RuleText.at("辰午申戌子寅辰午申戌子寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:934  '巳辰卯寅丑子亥戌酉申未午'[men] in d
        GodRule("殃败", kind: .demon, line: 934, recommends: [], avoids: []) { e in
            (needle: RuleText.at("巳辰卯寅丑子亥戌酉申未午", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:935  '巳申寅亥巳申寅亥巳申寅亥'[men] in d
        GodRule("雷公", kind: .demon, line: 935, recommends: [], avoids: []) { e in
            (needle: RuleText.at("巳申寅亥巳申寅亥巳申寅亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:936  '申酉戌巳午未寅卯辰亥子丑'[men] in d
        GodRule("飞廉", kind: .demon, line: 936, recommends: [], avoids: ["纳畜", "修造", "搬移", "嫁娶"]) { e in
            (needle: RuleText.at("申酉戌巳午未寅卯辰亥子丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:937  '申酉戌巳午未寅卯辰亥子丑'[men] in d
        GodRule("大煞", kind: .demon, line: 937, recommends: [], avoids: ["安抚边境", "选将", "出师"]) { e in
            (needle: RuleText.at("申酉戌巳午未寅卯辰亥子丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:939  '申巳辰丑戌未卯子酉午寅亥'[men] in d
        GodRule("枯鱼", kind: .demon, line: 939, recommends: [], avoids: ["栽种"]) { e in
            (needle: RuleText.at("申巳辰丑戌未卯子酉午寅亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:940  '戌未辰丑戌未辰丑戌未辰丑'[men] in d
        GodRule("九空", kind: .demon, line: 940, recommends: [], avoids: ["进人口", "修仓库", "开市", "立券交易", "纳财", "开仓"]) { e in
            (needle: RuleText.at("戌未辰丑戌未辰丑戌未辰丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:941  '酉戌亥子丑寅卯辰巳午未申'[men] in d
        GodRule("八座", kind: .demon, line: 941, recommends: [], avoids: []) { e in
            (needle: RuleText.at("酉戌亥子丑寅卯辰巳午未申", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:942  d in ('丁丑己酉', '甲申甲辰', '辛未丁未', '甲戌甲寅')[sn]
        GodRule("八风触水龙", kind: .demon, line: 942, recommends: [], avoids: ["取鱼", "乘船渡水"]) { e in
            (needle: .text(e.dayPillar), container: .text(RuleText.pick(["丁丑己酉", "甲申甲辰", "辛未丁未", "甲戌甲寅"], e.seasonIndex)))
        },
        // lunar.py:943  '午子丑未寅申卯酉辰戌巳亥'[men] in d
        GodRule("血忌", kind: .demon, line: 943, recommends: [], avoids: ["针刺"]) { e in
            (needle: RuleText.at("午子丑未寅申卯酉辰戌巳亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:944  '壬子癸丑庚寅辛卯庚辰丁巳丙午丁未甲申乙酉甲戌癸亥'[men * 2:men * 2 + 2] in d
        GodRule("阴错", kind: .demon, line: 944, recommends: [], avoids: []) { e in
            (needle: RuleText.slice("壬子癸丑庚寅辛卯庚辰丁巳丙午丁未甲申乙酉甲戌癸亥", e.monthBranchIndex * 2, e.monthBranchIndex * 2 + 2), container: .text(e.dayPillar))
        },
        // lunar.py:945  ldn in (3, 7, 13, 18, 22, 27)
        GodRule("三娘煞", kind: .demon, line: 945, recommends: [], avoids: ["嫁娶", "结婚姻"]) { e in
            (needle: .integer(e.lunarDay), container: .elements([.integer(3), .integer(7), .integer(13), .integer(18), .integer(22), .integer(27)]))
        },
        // lunar.py:946  tmd in t4j
        GodRule("四绝", kind: .demon, line: 946, recommends: [], avoids: ["出行", "上官", "嫁娶", "进人口", "搬移", "开市", "立券交易", "祭祀"]) { e in
            (needle: .monthDay(month: e.tomorrow.month, day: e.tomorrow.day), container: .elements(e.fourJueDates))
        },
        // lunar.py:947  tmd in t4l
        GodRule("四离", kind: .demon, line: 947, recommends: [], avoids: ["出行", "嫁娶"]) { e in
            (needle: .monthDay(month: e.tomorrow.month, day: e.tomorrow.day), container: .elements(e.fourLiDates))
        },
        // lunar.py:948  '未未戌戌戌丑丑丑辰辰辰未'[men] in d
        GodRule("四击", kind: .demon, line: 948, recommends: [], avoids: ["安抚边境", "选将", "出师"]) { e in
            (needle: RuleText.at("未未戌戌戌丑丑丑辰辰辰未", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:951  d in ('壬子', '乙卯', '戊午', '辛酉')[sn]
        GodRule("四耗", kind: .demon, line: 951, recommends: [], avoids: ["安抚边境", "选将", "出师", "修仓库", "开市", "立券交易", "纳财", "开仓"]) { e in
            (needle: .text(e.dayPillar), container: .text(RuleText.pick(["壬子", "乙卯", "戊午", "辛酉"], e.seasonIndex)))
        },
        // lunar.py:952  d in ('乙亥', '丁亥', '辛亥', '癸亥')[sn]
        GodRule("四穷", kind: .demon, line: 952, recommends: [], avoids: ["安抚边境", "选将", "出师", "结婚姻", "纳采", "嫁娶", "进人口", "修仓库", "开市", "立券交易", "纳财", "开仓", "安葬"]) { e in
            (needle: .text(e.dayPillar), container: .text(RuleText.pick(["乙亥", "丁亥", "辛亥", "癸亥"], e.seasonIndex)))
        },
        // lunar.py:954  d in ('甲子', '丙子', '庚子', '壬子')[sn]
        GodRule("四忌", kind: .demon, line: 954, recommends: [], avoids: ["安抚边境", "选将", "出师", "结婚姻", "纳采", "嫁娶", "安葬"]) { e in
            (needle: .text(e.dayPillar), container: .text(RuleText.pick(["甲子", "丙子", "庚子", "壬子"], e.seasonIndex)))
        },
        // lunar.py:955  d in ('庚申辛酉', '壬子癸亥', '甲寅乙卯', '丁巳丙午')[sn]
        GodRule("四废", kind: .demon, line: 955, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "颁诏", "施恩", "招贤", "举正直", "宣政事", "布政事", "庆赐", "宴会", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "求医疗病", "裁制", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "鼓铸", "经络", "酝酿", "开市", "立券交易", "纳财", "开仓", "修置产室", "开渠", "穿井", "安碓硙", "塞穴", "补垣", "修饰垣墙", "栽种", "牧养", "纳畜", "破土", "安葬", "启攒"]) { e in
            (needle: .text(e.dayPillar), container: .text(RuleText.pick(["庚申辛酉", "壬子癸亥", "甲寅乙卯", "丁巳丙午"], e.seasonIndex)))
        },
        // lunar.py:960  ['壬辰', '戊辰', '乙未', '乙未', '戊辰', '丙戌', '丙戌', '戊辰', '辛丑', '辛丑', '戊辰', '壬辰'][men] in d
        GodRule("五墓", kind: .demon, line: 960, recommends: [], avoids: ["冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "求医疗病", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "开市", "立券交易", "修置产室", "栽种", "牧养", "纳畜", "破土", "安葬", "启攒"]) { e in
            (needle: .text(RuleText.pick(["壬辰", "戊辰", "乙未", "乙未", "戊辰", "丙戌", "丙戌", "戊辰", "辛丑", "辛丑", "戊辰", "壬辰"], e.monthBranchIndex)), container: .text(e.dayPillar))
        },
        // lunar.py:963  d[1] in ['巳酉丑', '申子辰', '亥卯未', '寅午戌'][sn]
        GodRule("五虚", kind: .demon, line: 963, recommends: [], avoids: ["修仓库", "开仓"]) { e in
            (needle: .text(e.dayBranch), container: .text(RuleText.pick(["巳酉丑", "申子辰", "亥卯未", "寅午戌"], e.seasonIndex)))
        },
        // lunar.py:964  d[1] in '申酉'
        GodRule("五离", kind: .demon, line: 964, recommends: ["沐浴"], avoids: ["庆赐", "宴会", "结婚姻", "纳采", "立券交易"]) { e in
            (needle: .text(e.dayBranch), container: .text("申酉"))
        },
        // lunar.py:965  '未戌午寅辰酉卯申丑巳子亥'[men] in d
        GodRule("五鬼", kind: .demon, line: 965, recommends: [], avoids: ["出行"]) { e in
            (needle: RuleText.at("未戌午寅辰酉卯申丑巳子亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:966  d in ['丁未', '己未', '庚申', '甲寅', '癸丑']
        GodRule("八专", kind: .demon, line: 966, recommends: [], avoids: ["安抚边境", "选将", "出师", "结婚姻", "纳采", "嫁娶"]) { e in
            (needle: .text(e.dayPillar), container: RuleText.texts(["丁未", "己未", "庚申", "甲寅", "癸丑"]))
        },
        // lunar.py:967  '申巳辰丑戌未卯子酉午寅亥'[men] in d
        GodRule("九坎", kind: .demon, line: 967, recommends: [], avoids: ["塞穴", "补垣", "取鱼", "乘船渡水"]) { e in
            (needle: RuleText.at("申巳辰丑戌未卯子酉午寅亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:969  '申巳辰丑戌未卯子酉午寅亥'[men] in d
        GodRule("九焦", kind: .demon, line: 969, recommends: [], avoids: ["鼓铸", "栽种"]) { e in
            (needle: RuleText.at("申巳辰丑戌未卯子酉午寅亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:973  '乙卯丙午辛酉壬子'[sn * 2:sn * 2 + 2] in d
        GodRule("天转", kind: .demon, line: 973, recommends: [], avoids: ["修造", "搬移", "嫁娶"]) { e in
            (needle: RuleText.slice("乙卯丙午辛酉壬子", e.seasonIndex * 2, e.seasonIndex * 2 + 2), container: .text(e.dayPillar))
        },
        // lunar.py:974  '辛卯戊午癸酉丙子'[sn * 2:sn * 2 + 2] in d
        GodRule("地转", kind: .demon, line: 974, recommends: [], avoids: ["修造", "搬移", "嫁娶"]) { e in
            (needle: RuleText.slice("辛卯戊午癸酉丙子", e.seasonIndex * 2, e.seasonIndex * 2 + 2), container: .text(e.dayPillar))
        },
        // lunar.py:975  '卯午酉子'[sn] in d
        GodRule("月建转杀", kind: .demon, line: 975, recommends: [], avoids: ["修造"]) { e in
            (needle: RuleText.at("卯午酉子", e.seasonIndex), container: .text(e.dayPillar))
        },
        // lunar.py:976  d[1] in '巳酉丑申子辰亥卯未寅午戌'[sn * 3:sn * 3 + 3]
        GodRule("荒芜", kind: .demon, line: 976, recommends: [], avoids: []) { e in
            (needle: .text(e.dayBranch), container: .text(PyString.slice("巳酉丑申子辰亥卯未寅午戌", e.seasonIndex * 3, e.seasonIndex * 3 + 3)))
        },
        // lunar.py:978  '戌子寅辰午申'[men % 6] in d
        GodRule("蚩尤", kind: .demon, line: 978, recommends: [], avoids: []) { e in
            (needle: RuleText.at("戌子寅辰午申", e.monthBranchIndex % 6), container: .text(e.dayPillar))
        },
        // lunar.py:979  '酉午卯子酉午卯子酉午卯子'[men] in d
        GodRule("大时", kind: .demon, line: 979, recommends: [], avoids: ["祈福", "求嗣", "上册", "上表章", "施恩", "招贤", "举正直", "冠带", "出行", "安抚边境", "选将", "出师", "上官", "临政", "结婚姻", "纳采", "嫁娶", "进人口", "搬移", "安床", "解除", "求医疗病", "营建", "修宫室", "缮城郭", "筑堤防", "修造", "竖柱上梁", "修仓库", "开市", "立券交易", "纳财", "开仓", "修置产室", "栽种", "牧养", "纳畜"]) { e in
            (needle: RuleText.at("酉午卯子酉午卯子酉午卯子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:984  '酉午卯子酉午卯子酉午卯子'[men] in d
        GodRule("大败", kind: .demon, line: 984, recommends: [], avoids: []) { e in
            (needle: RuleText.at("酉午卯子酉午卯子酉午卯子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:988  '酉午卯子酉午卯子酉午卯子'[men] in d
        GodRule("咸池", kind: .demon, line: 988, recommends: [], avoids: ["嫁娶", "取鱼", "乘船渡水"]) { e in
            (needle: RuleText.at("酉午卯子酉午卯子酉午卯子", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:990  '申子丑巳酉寅午戌卯未亥辰'[men] in d
        GodRule("土符", kind: .demon, line: 990, recommends: [], avoids: ["营建", "修宫室", "缮城郭", "筑堤防", "修造", "修仓库", "修置产室", "开渠", "穿井", "安碓硙", "补垣", "修饰垣墙", "平治道涂", "破屋坏垣", "栽种", "破土"]) { e in
            (needle: RuleText.at("申子丑巳酉寅午戌卯未亥辰", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:993  '子丑寅卯辰巳午未申酉戌亥'[men] in d
        GodRule("土府", kind: .demon, line: 993, recommends: [], avoids: ["营建", "修宫室", "缮城郭", "筑堤防", "修造", "修仓库", "修置产室", "开渠", "穿井", "安碓硙", "补垣", "修饰垣墙", "平治道涂", "破屋坏垣", "栽种", "破土"]) { e in
            (needle: RuleText.at("子丑寅卯辰巳午未申酉戌亥", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:996  (datetime(self.nextSolarTermYear, twys[0], twys[1]) - self.date).days in range(0, 18)
        GodRule("土王用事", kind: .demon, line: 996, recommends: [], avoids: ["营建", "修宫室", "缮城郭", "筑堤防", "修造", "修仓库", "修置产室", "开渠", "穿井", "安碓硙", "补垣", "修饰垣墙", "平治道涂", "破屋坏垣", "栽种", "破土"]) { e in
            (needle: e.earthKingDays, container: .integerRange(lower: 0, upperExclusive: 18))
        },
        // lunar.py:999  '亥子丑寅卯辰巳午未申酉戌'[men] in d
        GodRule("血支", kind: .demon, line: 999, recommends: [], avoids: ["针刺"]) { e in
            (needle: RuleText.at("亥子丑寅卯辰巳午未申酉戌", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:1001  '亥申巳寅亥申巳寅亥申巳寅'[men] in d
        GodRule("游祸", kind: .demon, line: 1001, recommends: [], avoids: ["祈福", "求嗣", "解除", "求医疗病"]) { e in
            (needle: RuleText.at("亥申巳寅亥申巳寅亥申巳寅", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:1003  '寅子丑寅子丑寅子丑寅子丑'[men] in d
        GodRule("归忌", kind: .demon, line: 1003, recommends: [], avoids: ["搬移", "远回"]) { e in
            (needle: RuleText.at("寅子丑寅子丑寅子丑寅子丑", e.monthBranchIndex), container: .text(e.dayPillar))
        },
        // lunar.py:1005  (lmn, d) in [(4, '戊午'), (4, '丙午'), (10, '壬子'), (10, '戊子')]
        GodRule("岁薄", kind: .demon, line: 1005, recommends: [], avoids: []) { e in
            (needle: .monthPillar(month: e.lunarMonth, pillar: e.dayPillar), container: .elements([.monthPillar(month: 4, pillar: "戊午"), .monthPillar(month: 4, pillar: "丙午"), .monthPillar(month: 10, pillar: "壬子"), .monthPillar(month: 10, pillar: "戊子")]))
        },
        // lunar.py:1006  (lmn, d) in [(6, '戊午'), (6, '丙午'), (12, '壬子'), (12, '戊子')]
        GodRule("逐阵", kind: .demon, line: 1006, recommends: [], avoids: []) { e in
            (needle: .monthPillar(month: e.lunarMonth, pillar: e.dayPillar), container: .elements([.monthPillar(month: 6, pillar: "戊午"), .monthPillar(month: 6, pillar: "丙午"), .monthPillar(month: 12, pillar: "壬子"), .monthPillar(month: 12, pillar: "戊子")]))
        },
        // lunar.py:1007  (lmn, d) in [(10, '丁巳')]
        GodRule("阴阳交破", kind: .demon, line: 1007, recommends: [], avoids: []) { e in
            (needle: .monthPillar(month: e.lunarMonth, pillar: e.dayPillar), container: .elements([.monthPillar(month: 10, pillar: "丁巳")]))
        },
        // lunar.py:1008  d in ['丁未', '丁丑', '丙戌', '甲午', '庚子', '壬寅', '癸卯', '乙巳', '戊申', '己酉', '辛亥', '丙辰']
        GodRule("宝日", kind: .demon, line: 1008, recommends: [], avoids: []) { e in
            (needle: .text(e.dayPillar), container: RuleText.texts(["丁未", "丁丑", "丙戌", "甲午", "庚子", "壬寅", "癸卯", "乙巳", "戊申", "己酉", "辛亥", "丙辰"]))
        },
        // lunar.py:1009  d in ['甲子', '丙寅', '丁卯', '己巳', '辛未', '壬申', '癸酉', '乙亥', '庚辰', '辛丑', '庚戌', '戊午']
        GodRule("义日", kind: .demon, line: 1009, recommends: [], avoids: []) { e in
            (needle: .text(e.dayPillar), container: RuleText.texts(["甲子", "丙寅", "丁卯", "己巳", "辛未", "壬申", "癸酉", "乙亥", "庚辰", "辛丑", "庚戌", "戊午"]))
        },
        // lunar.py:1010  d in ['乙丑', '甲戌', '壬午', '戊子', '庚寅', '辛卯', '癸巳', '乙未', '丙申', '丁酉', '己亥', '甲辰']
        GodRule("制日", kind: .demon, line: 1010, recommends: [], avoids: []) { e in
            (needle: .text(e.dayPillar), container: RuleText.texts(["乙丑", "甲戌", "壬午", "戊子", "庚寅", "辛卯", "癸巳", "乙未", "丙申", "丁酉", "己亥", "甲辰"]))
        },
        // lunar.py:1011  d in ['庚午', '辛巳', '丙子', '戊寅', '己卯', '癸未', '癸丑', '甲申', '乙酉', '丁亥', '壬辰', '壬戌']
        GodRule("伐日", kind: .demon, line: 1011, recommends: [], avoids: ["安抚边境", "选将", "出师"]) { e in
            (needle: .text(e.dayPillar), container: RuleText.texts(["庚午", "辛巳", "丙子", "戊寅", "己卯", "癸未", "癸丑", "甲申", "乙酉", "丁亥", "壬辰", "壬戌"]))
        },
        // lunar.py:1013  d in ['甲寅', '乙卯', '丁巳', '丙午', '庚申', '辛酉', '癸亥', '壬子', '戊辰', '戊戌', '己丑', '己未']
        GodRule("专日", kind: .demon, line: 1013, recommends: [], avoids: ["安抚边境", "选将", "出师"]) { e in
            (needle: .text(e.dayPillar), container: RuleText.texts(["甲寅", "乙卯", "丁巳", "丙午", "庚申", "辛酉", "癸亥", "壬子", "戊辰", "戊戌", "己丑", "己未"]))
        },
        // lunar.py:1015  d[1] in '巳亥'
        GodRule("重日", kind: .demon, line: 1015, recommends: [], avoids: ["破土", "安葬", "启攒"]) { e in
            (needle: .text(e.dayBranch), container: .text("巳亥"))
        },
        // lunar.py:1016  '癸巳甲乙戊丙丁巳庚辛戊壬'[men] in d
        GodRule("复日", kind: .demon, line: 1016, recommends: ["裁制"], avoids: ["破土", "安葬", "启攒"]) { e in
            (needle: RuleText.at("癸巳甲乙戊丙丁巳庚辛戊壬", e.monthBranchIndex), container: .text(e.dayPillar))
        },
    ]
}

/// Constants referenced by the demon table.
public enum UpstreamRuleConstants {
    /// `mrY13` (lunar.py:642): 杨公十三忌 as lunar `(month, day)` pairs.
    public static let yangGongTaboos: [RuleOperand] = [
        .monthDay(month: 1, day: 13), .monthDay(month: 2, day: 11), .monthDay(month: 3, day: 9), .monthDay(month: 4, day: 7),
        .monthDay(month: 5, day: 5), .monthDay(month: 6, day: 2), .monthDay(month: 7, day: 1), .monthDay(month: 7, day: 29),
        .monthDay(month: 8, day: 27), .monthDay(month: 9, day: 25), .monthDay(month: 10, day: 23), .monthDay(month: 11, day: 21),
        .monthDay(month: 12, day: 19),
    ]
}
