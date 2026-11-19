// Stable token wrappers for upstream vocabulary. Logic never compares free strings;
// it compares these wrappers, whose raw values are the upstream Simplified Chinese
// spellings (source tokens, not the application's display vocabulary).

/// An activity token (宜/忌 item) exactly as spelled by upstream.
public struct AlmanacActivity: RawRepresentable, Sendable, Hashable, Comparable {
    public let rawValue: String
    /// Code points, precomputed so equality, hashing and ordering are exact and fast.
    private let scalars: [UInt32]

    public init(rawValue: String) {
        self.rawValue = rawValue
        self.scalars = rawValue.unicodeScalars.map(\.value)
    }
    public init(_ rawValue: String) { self.init(rawValue: rawValue) }

    public static func == (lhs: AlmanacActivity, rhs: AlmanacActivity) -> Bool { lhs.scalars == rhs.scalars }
    public func hash(into hasher: inout Hasher) { hasher.combine(scalars) }

    /// Code-point order; used as the deterministic tie-break for tokens outside `thingsSort`.
    public static func < (lhs: AlmanacActivity, rhs: AlmanacActivity) -> Bool {
        lhs.scalars.lexicographicallyPrecedes(rhs.scalars)
    }

    // Tokens referenced by evaluator logic (seasonal additions, exception blocks, sentinels).
    public static let quYu = AlmanacActivity("取鱼")
    public static let tianLie = AlmanacActivity("畋猎")
    public static let faMu = AlmanacActivity("伐木")
    public static let zhengShouZuJia = AlmanacActivity("整手足甲")
    public static let zhengRong = AlmanacActivity("整容")
    public static let tiTou = AlmanacActivity("剃头")
    public static let qiuYiLiaoBing = AlmanacActivity("求医疗病")
    public static let xuanZhengShi = AlmanacActivity("宣政事")
    public static let buZhengShi = AlmanacActivity("布政事")
    public static let yingJianGongShi = AlmanacActivity("营建宫室")
    public static let xiuGongShi = AlmanacActivity("修宫室")
    public static let jinRenKou = AlmanacActivity("进人口")
    public static let anChuang = AlmanacActivity("安床")
    public static let jingLuo = AlmanacActivity("经络")
    public static let yunNiang = AlmanacActivity("酝酿")
    public static let kaiShi = AlmanacActivity("开市")
    public static let liQuanJiaoYi = AlmanacActivity("立券交易")
    public static let naCai = AlmanacActivity("纳财")
    public static let kaiCangKu = AlmanacActivity("开仓库")
    public static let chuHuoCai = AlmanacActivity("出货财")
    public static let jiSi = AlmanacActivity("祭祀")
    public static let qiuFu = AlmanacActivity("求福")
    public static let qiSi = AlmanacActivity("祈嗣")
    public static let chuanJing = AlmanacActivity("穿井")
    public static let kaiQu = AlmanacActivity("开渠")
    public static let chuXing = AlmanacActivity("出行")
    public static let chuShi = AlmanacActivity("出师")
    public static let qianShi = AlmanacActivity("遣使")
    public static let yanHui = AlmanacActivity("宴会")
    public static let qingCi = AlmanacActivity("庆赐")
    public static let shangHe = AlmanacActivity("赏贺")
    public static let qiFu = AlmanacActivity("祈福")
    public static let qiuSi = AlmanacActivity("求嗣")
    public static let jieHunYin = AlmanacActivity("结婚姻")
    public static let guanDai = AlmanacActivity("冠带")
    public static let naCaiWenMing = AlmanacActivity("纳采问名")
    public static let jiaQu = AlmanacActivity("嫁娶")
    public static let banYi = AlmanacActivity("搬移")
    public static let jieChu = AlmanacActivity("解除")
    public static let xiuZao = AlmanacActivity("修造")
    public static let shuZhuShangLiang = AlmanacActivity("竖柱上梁")
    public static let shanChengGuo = AlmanacActivity("缮城郭")
    public static let zhuTi = AlmanacActivity("筑提")
    public static let xiuCangKu = AlmanacActivity("修仓库")
    public static let guZhu = AlmanacActivity("鼓铸")
    public static let shanGai = AlmanacActivity("苫盖")
    public static let xiuZhiChanShi = AlmanacActivity("修置产室")
    public static let kaiQuChuanJing = AlmanacActivity("开渠穿井")
    public static let anDuiWei = AlmanacActivity("安碓硙")
    public static let buYuanSaiXue = AlmanacActivity("补垣塞穴")
    public static let xiuShiYuanQiang = AlmanacActivity("修饰垣墙")
    public static let pingZhiDaoTu = AlmanacActivity("平治道涂")
    public static let poWuHuaiYuan = AlmanacActivity("破屋坏垣")
    public static let muYang = AlmanacActivity("牧养")
    public static let naChu = AlmanacActivity("纳畜")
    public static let anZang = AlmanacActivity("安葬")
    public static let qiCuan = AlmanacActivity("启攒")
    public static let poTu = AlmanacActivity("破土")
    public static let zhaoMingGongQing = AlmanacActivity("诏命公卿")
    public static let zhaoXian = AlmanacActivity("招贤")
    public static let shiEn = AlmanacActivity("施恩")
    public static let juZhengZhi = AlmanacActivity("举正直")
    public static let banZhao = AlmanacActivity("颁诏")
    public static let buYuan = AlmanacActivity("补垣")
    public static let saiXue = AlmanacActivity("塞穴")
    public static let muYu = AlmanacActivity("沐浴")
    /// Output sentinel "nothing is suitable" (lunar.py:1066, 1276).
    public static let nothingSuitable = AlmanacActivity("诸事不宜")
    /// Output sentinel "nothing is avoided" (lunar.py:1257, 1260, 1274).
    public static let nothingAvoided = AlmanacActivity("诸事不忌")
}

/// A god (神煞) name exactly as spelled by upstream.
public struct AlmanacGodName: RawRepresentable, Sendable, Hashable, Comparable {
    public let rawValue: String
    private let scalars: [UInt32]

    public init(rawValue: String) {
        self.rawValue = rawValue
        self.scalars = rawValue.unicodeScalars.map(\.value)
    }
    public init(_ rawValue: String) { self.init(rawValue: rawValue) }

    public static func == (lhs: AlmanacGodName, rhs: AlmanacGodName) -> Bool { lhs.scalars == rhs.scalars }
    public func hash(into hasher: inout Hasher) { hasher.combine(scalars) }

    public static func < (lhs: AlmanacGodName, rhs: AlmanacGodName) -> Bool {
        lhs.scalars.lexicographicallyPrecedes(rhs.scalars)
    }

    /// Whether the name contains 岁, which `yeargod="noduty"` skips (lunar.py:1027–1029).
    public var isYearGod: Bool { rawValue.unicodeScalars.contains("岁") }

    // Names referenced by evaluator logic.
    public static let suiDe = AlmanacGodName("岁德")
    public static let suiDeHe = AlmanacGodName("岁德合")
    public static let yueDe = AlmanacGodName("月德")
    public static let yueDeHe = AlmanacGodName("月德合")
    public static let tianDe = AlmanacGodName("天德")
    public static let tianDeHe = AlmanacGodName("天德合")
    public static let tianShe = AlmanacGodName("天赦")
    public static let tianYuan = AlmanacGodName("天愿")
    public static let yueEn = AlmanacGodName("月恩")
    public static let siXiang = AlmanacGodName("四相")
    public static let shiDe = AlmanacGodName("时德")
    public static let buJiang = AlmanacGodName("不将")
    public static let mingFei = AlmanacGodName("鸣吠")
    public static let mingFeiDui = AlmanacGodName("鸣吠对")
    public static let wangWang = AlmanacGodName("往亡")
    public static let yueYan = AlmanacGodName("月厌")
    public static let tuFu = AlmanacGodName("土府")
    public static let tuFuSymbol = AlmanacGodName("土符")
    public static let diNang = AlmanacGodName("地囊")
    public static let tianGou = AlmanacGodName("天狗")
    public static let siJi = AlmanacGodName("四忌")
    public static let siQiong = AlmanacGodName("四穷")
}
