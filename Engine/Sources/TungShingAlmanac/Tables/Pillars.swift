// Upstream cycle tables ported verbatim from the pinned OPN48/cnlunar `config.py`
// (commit 3f674fe0f458b480c79eaaf5464f43f4bc815a91, MIT; see NOTICES.md).
// Every array keeps upstream element order because rule predicates index into them.
// Source Simplified Chinese spellings are retained as stable tokens; they are not
// the application's display vocabulary.

/// Verbatim cycle, label and lookup tables from `cnlunar/config.py`.
///
/// The tables are data for the faithful port. Line numbers in doc comments refer to
/// the pinned `config.py`.
public enum UpstreamTables {
    /// `the10HeavenlyStems` (config.py:17).
    public static let heavenlyStems: [String] = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    /// `the10HeavenlyStems5ElementsList` (config.py:18).
    public static let heavenlyStemElements: [String] = ["木", "木", "火", "火", "土", "土", "金", "金", "水", "水"]
    /// `the12EarthlyBranches` (config.py:19).
    public static let earthlyBranches: [String] = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    /// `the12EarthlyBranches5ElementsList` (config.py:20).
    public static let earthlyBranchElements: [String] = ["水", "土", "木", "木", "土", "火", "火", "土", "金", "金", "土", "水"]

    /// `the60HeavenlyEarth` (config.py:21): index 0 is 甲子, index 59 is 癸亥.
    public static let sexagenary: [String] = (0..<60).map { i in
        heavenlyStems[i % 10] + earthlyBranches[i % 12]
    }

    /// `theHalf60HeavenlyEarth5ElementsList` (config.py:23): 納音 for sexagenary pair `index / 2`.
    public static let nayin: [String] = [
        "海中金", "炉中火", "大林木", "路旁土", "剑锋金", "山头火", "涧下水", "城头土", "白蜡金", "杨柳木", "井泉水",
        "屋上土", "霹雳火", "松柏木", "长流水", "砂中金", "山下火", "平地木", "壁上土", "金箔金", "覆灯火", "天河水",
        "大驿土", "钗钏金", "桑柘木", "大溪水", "砂中土", "天上火", "石榴木", "大海水",
    ]

    /// `the28StarsList` (config.py:26).
    public static let mansions: [String] = [
        "角木蛟", "亢金龙", "氐土貉", "房日兔", "心月狐", "尾火虎", "箕水豹", "斗木獬", "牛金牛", "女土蝠", "虚日鼠", "危月燕", "室火猪", "壁水貐",
        "奎木狼", "娄金狗", "胃土雉", "昴日鸡", "毕月乌", "觜火猴", "参水猿", "井木犴", "鬼金羊", "柳土獐", "星日马", "张月鹿", "翼火蛇", "轸水蚓",
    ]

    /// `pengTatooList` (config.py:28): ten stem rows followed by twelve branch rows.
    public static let pengTaboo: [String] = [
        "甲不开仓 财物耗散", "乙不栽植 千株不长", "丙不修灶 必见灾殃", "丁不剃头 头必生疮", "戊不受田 田主不祥", "己不破券 二比并亡", "庚不经络 织机虚张", "辛不合酱 主人不尝",
        "壬不泱水 更难提防", "癸不词讼 理弱敌强", "子不问卜 自惹祸殃", "丑不冠带 主不还乡", "寅不祭祀 神鬼不尝", "卯不穿井 水泉不香", "辰不哭泣 必主重丧", "巳不远行 财物伏藏",
        "午不苫盖 屋主更张", "未不服药 毒气入肠", "申不安床 鬼祟入房", "酉不会客 醉坐颠狂", "戌不吃犬 作怪上床", "亥不嫁娶 不利新郎",
    ]

    /// `chineseZodiacNameList` (config.py:31).
    public static let zodiacAnimals: [String] = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    /// `chinese12DayOfficers` (config.py:32).
    public static let dayOfficers: [String] = ["建", "除", "满", "平", "定", "执", "破", "危", "成", "收", "开", "闭"]
    /// `chinese12DayGods` (config.py:34).
    public static let dayGods: [String] = ["青龙", "明堂", "天刑", "朱雀", "金贵", "天德", "白虎", "玉堂", "天牢", "玄武", "司命", "勾陈"]
    /// Yellow-path positions used by `get_today12DayOfficer` (lunar.py:414).
    public static let yellowPathGodIndices: [Int] = [0, 1, 4, 5, 7, 10]
    /// 青龙 start offsets per month branch used at lunar.py:412.
    public static let eclipticStartByMonthBranch: [Int] = [8, 10, 0, 2, 4, 6, 8, 10, 0, 2, 4, 6]

    /// `directionList` (config.py:36).
    public static let directions: [String] = ["正北", "东北", "正东", "东南", "正南", "西南", "正西", "西北"]
    /// `chinese8Trigrams` (config.py:37).
    public static let trigrams: [String] = ["坎", "艮", "震", "巽", "离", "坤", "兑", "乾"]
    /// `luckyGodDirection` (config.py:39), indexed by day stem.
    public static let luckyGodDirection: [String] = ["艮", "乾", "坤", "离", "巽", "艮", "乾", "坤", "离", "巽"]
    /// `wealthGodDirection` (config.py:40).
    public static let wealthGodDirection: [String] = ["艮", "艮", "坤", "坤", "坎", "坎", "震", "震", "离", "离"]
    /// `mascotGodDirection` (config.py:41).
    public static let mascotGodDirection: [String] = ["坎", "坤", "乾", "巽", "艮", "坎", "坤", "乾", "巽", "艮"]
    /// `sunNobleDirection` (config.py:42).
    public static let sunNobleDirection: [String] = ["坤", "坤", "兑", "乾", "艮", "坎", "离", "艮", "震", "巽"]
    /// `moonNobleDirection` (config.py:43).
    public static let moonNobleDirection: [String] = ["艮", "坎", "乾", "兑", "坤", "坤", "艮", "离", "巽", "震"]

    /// `fetalGodList` (config.py:45), indexed by day sexagenary index.
    public static let fetalGods: [String] = [
        "碓磨门外东南", "碓磨厕外东南", "厨灶炉外正南", "仓库门外正南", "房床厕外正南", "占门床外正南", "占碓磨外正南", "厨灶厕外西南", "仓库炉外西南", "房床门外西南", "门碓栖外西南", "碓磨床外西南",
        "厨灶碓外西南", "仓库厕外西南", "房床厕外正南", "房床炉外正西", "碓磨栖外正西", "厨灶床外正西", "仓库碓外西北", "房床厕外西北", "占门炉外西北", "碓磨门外西北", "厨灶栖外西北", "仓库床外西北",
        "房床碓外正北", "占门厕外正北", "碓磨炉外正北", "厨灶门外正北", "仓库栖外正北", "占房床房内北", "占门碓房内北", "碓磨门房内北", "厨灶炉房内北", "仓库门房内北", "房床栖房内中", "占门床房内中",
        "占碓磨房内南", "厨灶厕房内南", "仓库炉房内南", "房床门房内南", "门鸡栖房内东", "碓磨床房内东", "厨灶碓房内东", "仓库厕房内东", "房床炉房内东", "占大门外东北", "碓磨栖外东北", "厨灶床外东北",
        "仓库碓外东北", "房床厕外东北", "占门炉外东北", "碓磨门外正东", "厨灶栖外正东", "仓库床外正东", "房床碓外正东", "占门厕外正东", "碓磨炉外东南", "仓库栖外东南", "占房床外东南", "占门碓外东南",
    ]

    /// `meridiansName` (config.py:51), indexed by double-hour number.
    public static let meridians: [String] = ["胆", "肝", "肺", "大肠", "胃", "脾", "心", "小肠", "膀胱", "肾", "心包", "三焦"]

    /// `lunarMonthNameList` (config.py:53).
    public static let lunarMonthNames: [String] = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
    /// `lunarDayNameList` (config.py:54).
    public static let lunarDayNames: [String] = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十",
    ]
    /// `upperNum` (config.py:57).
    public static let upperNumerals: [String] = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
    /// `weekDay` (config.py:58), Monday first (Python `weekday()`).
    public static let weekdays: [String] = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]

    /// `SOLAR_TERMS_NAME_LIST` (config.py:10): upstream term order starting at 小寒.
    public static let solarTermNames: [String] = [
        "小寒", "大寒",
        "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
        "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
        "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
        "立冬", "小雪", "大雪", "冬至",
    ]
    /// `EAST_ZODIAC_LIST` (config.py:16).
    public static let eastZodiac: [String] = ["玄枵", "娵訾", "降娄", "大梁", "实沈", "鹑首", "鹑火", "鹑尾", "寿星", "大火", "析木", "星纪"]
    /// `STAR_ZODIAC_NAME` (config.py:4).
    public static let starZodiacNames: [String] = ["摩羯座", "水瓶座", "双鱼座", "白羊座", "金牛座", "双子座", "巨蟹座", "狮子座", "处女座", "天秤座", "天蝎座", "射手座"]
    /// `STAR_ZODIAC_DATE` (config.py:5) as (month, day) boundaries.
    public static let starZodiacBoundaries: [(month: Int, day: Int)] = [
        (1, 20), (2, 19), (3, 21), (4, 21), (5, 21), (6, 22), (7, 23), (8, 23), (9, 23), (10, 23), (11, 23), (12, 23),
    ]

    /// `twohourLuckyTimeList` (config.py:159): 12-bit masks per day sexagenary index, bit 11 is 子.
    public static let doubleHourLuckMasks: [UInt16] = [
        0x2d3, 0xcb4, 0x32d, 0x4cb, 0xd32, 0xb4c, 0x2d3, 0xcb4, 0x32d, 0x4cb, 0xd22, 0xb5c,
        0x2d3, 0xcb4, 0x32d, 0x4cb, 0xd3a, 0xb4d, 0x2d3, 0xcb4, 0x32d, 0x4cb, 0xd32, 0xb4c,
        0x2d3, 0xcb5, 0x32d, 0x4cb, 0xd32, 0xb4c, 0x2d3, 0xcb4, 0x32d, 0x4cb, 0xd32, 0xb4c,
        0x2d3, 0xcb4, 0x32d, 0x4db, 0xd32, 0xb5c, 0x2d7, 0xcb4, 0x32d, 0x4cb, 0xd32, 0xb5c,
        0x2d3, 0xcb4, 0x32d, 0x4cb, 0xd32, 0xb4c, 0x2d3, 0xcb4, 0x30d, 0x4cb, 0xd32, 0xb4c,
    ]

    /// `SEASON_TYPE_STR` (lunar.py:17).
    public static let seasons: [String] = ["春", "夏", "秋", "冬"]
    /// `MONTH_TYPE_STR` (lunar.py:19); indexed by `monthEarthNum % 3`.
    public static let monthPositions: [String] = ["仲", "季", "孟"]

    /// Nine-star start list used by `get_the9FlyStar` (lunar.py:439).
    public static let flyStarStart: [Int] = [7, 3, 5, 6, 8, 1, 2, 4, 9]
}
