// Capability catalogue types. Being listed never makes an operation callable.

public enum CalendarCapability: String, Sendable, Hashable, CaseIterable, Comparable {
    case hkCalendarIdentity
    case hkGregorianLunarConversion
    case hkGregorianMonthFacts
    /// E2: daily 宜/忌 and almanac fields under the selected pinned evaluator profile.
    case almanacDailyActivities
    /// E6: the days of a closed interval judged for one or more activities by the accepted daily almanac, under the
    /// app profile ts-date-search-day-start-v1 (one Hong Kong civil day, judged on the day the activity begins) and a
    /// named selection policy. It collects the almanac's own one-day verdicts; every day it cannot judge stays in the
    /// result. Adds no source and no calculation of its own.
    case almanacDateSearch
    /// E3-BA: the Ba Zi relation chart (pillars, hidden stems, Ten Gods, growth stages, relations)
    /// with uncertain-birth-time alternatives, under the research profile ZP-REL-HK8-MIDNIGHT-v1.
    case baZiRelationChart
    /// E4-YJ: a recorded or deliberately generated six-line cast, its hexagram identity and structural
    /// transformations, and the passages a named reading profile selects (keys, never an interpretation),
    /// under the research reading profile qimeng.hufangping.received.v1. Consumes no calendar fact.
    case yijingCast
    /// E4-YJ: the separately admitted received Chinese passage corpus (edition
    /// zhouyi.wikisource.received.zh-hant.2026-10-22) that resolves selected passage keys to text.
    case yijingPassageCorpus
    /// E4-LY: the Six Yao chart of a preserved cast under najia.chart.v1 (palace, 世/應, Na Jia, the five relations
    /// against the original palace, hidden and useful candidates) and its time markers, read on the Hong Kong civil
    /// day and in the 節 month at the consultation instant. The chart consumes no calendar fact; the markers consume
    /// one E1 day and are unavailable, with their reason, wherever that day is not accepted. No judgment.
    case liuyaoNajiaChart
    /// E4-LY: the bounded 增刪卜易 judgment of a Six Yao chart for one of eight question contracts
    /// (najia.zengshan.bounded.v1, with the named variant najia.zengshan.recast_on_absent.v1): evidence lists, the
    /// useful spirit or its candidates, a typed outcome with every fired rule, and conditional timing filters. Never a
    /// score; the chart stays callable whatever this capability's review decides.
    case liuyaoZengshanJudgment
    /// E4-MH: a Meihua cast under its method's profile (meihua.time.v1, the family-name, text, speech and sound
    /// profiles, counted objects, object and direction): the arithmetic from the preserved inputs, 體/用, the nuclear
    /// pair with the 乾坤 exception, the initial, middle and ending relations and the season tags. The hour is the
    /// consultation instant's on the Hong Kong reference clock; a time cast reads the lunar date of that day and is
    /// unavailable, with its reason, wherever the day is not accepted. No activity reading.
    case meihuaCast
    /// E4-MH: the bounded activity reading of a Meihua cast under meihua.context.received.v1 for one of nine activities:
    /// the start and end cells of the matrix against the original 體, the middle relations, the season's tags, the
    /// activity's images and a typed outcome (a tendency, a staged reversal, a conflict, needs-context or unsupported).
    /// Never a score and never timing; the cast stays callable whatever this capability's review decides.
    case meihuaContextReading
    /// E4-TY: the corrected annual Taiyi chart (TY-JJMS-ANNUAL-v1) for a positive annual label, with 君基
    /// (TY-KING-ANCHOR30-v1), the pinned program's other markers and the bounded TY-ANNUAL-OBS-v1 observations.
    /// Consumes an annual label, never a day; it has no daily 宜/忌 and no verdict.
    case taiyiAnnualChart
    /// E4-TY: guarded source-case readers (TY-MS1883-ANNUAL-DOCUMENTARY-v1, all 72 received annual cases): a source
    /// case's printed claims attach to a chart only when its core fields match exactly; no verdict, no forecast.
    case taiyiSourceReadings
    /// E4-TY (research adoption N5): the 太乙淘金歌 annual chart of 古今圖書集成 藝術典687, a second Taiyi method never
    /// mixed with the first: the year counted from 至元元年甲子 1264 (TY-JICHENG687-ANNUAL-EPOCH1264-v1), the shared
    /// 72 bureau states, its 定計 fixed plan and its two door plates (TY-JICHENG687-DOOR-OPERATIONS-v1). No source
    /// case attaches and no verdict is drawn.
    case taiyiJichengAnnualChart
    /// E4-TY (research adoption P2): 太乙統宗寶鑑's annual stars and doors, a third Taiyi method never mixed with the
    /// other two: the year counted from 大德七年癸卯 1303, the nine-star director and plate with 卷六's generic grades
    /// (TY-TONGZONG6-NINE-STARS-v1) and the annual directing door (TY-TONGZONG12-ANNUAL-DOORS-v1). The source places no
    /// 太乙, eyes or generals, so no door plate is drawn, no source case attaches and no verdict is drawn.
    case taiyiTongzongAnnualPlates

    /// The E1 calendar capabilities, served by the pack-backed kernel.
    public static let calendarCapabilities: [CalendarCapability] = [.hkCalendarIdentity, .hkGregorianLunarConversion, .hkGregorianMonthFacts]

    public static func < (lhs: CalendarCapability, rhs: CalendarCapability) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// The eleven research families, spelled exactly as the research registry spells them.
public enum RegistryFamily: String, Sendable, Hashable, CaseIterable, Comparable {
    case almanac, bazi, ziwei, qimen, taiyi, yijing, liuyao, meihua
    case nineStarsFengShui = "nine_stars_feng_shui"
    case daLiuRen = "da_liu_ren"
    case qizhengSiyu = "qizheng_siyu"

    public static func < (lhs: RegistryFamily, rhs: RegistryFamily) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum VerificationStatus: Sendable, Hashable {
    case notAssessed
    case rejected(evidence: [EvidenceID])
    case accepted(manifest: EvidenceID)
}

/// What a build is made for. An acceptance record names the uses its sources are cleared for, and a pack's source
/// permission is decided for the running build's use: data cleared for development and internal builds only is
/// restricted, and so not callable, in a release build.
public enum ProductUse: String, Sendable, Hashable, CaseIterable {
    case development
    case internalBuild = "internal-build"
    case release
}

public enum SourcePermissionStatus: Sendable, Hashable {
    case unresolved
    case restricted(evidence: [EvidenceID])
    case permitted(evidence: [EvidenceID])
}

public struct CapabilityDescriptor: Sendable, Hashable {
    public let capability: CalendarCapability
    public let profile: ProfileID
    public let contracts: [ContractID]
    public let codeInstalled: Bool
    public let verification: VerificationStatus
    public let sourcePermission: SourcePermissionStatus
    public let productEnabled: Bool
    public let effectiveDomain: AcceptedDateDomain

    public init(capability: CalendarCapability, profile: ProfileID, contracts: [ContractID], codeInstalled: Bool,
                verification: VerificationStatus, sourcePermission: SourcePermissionStatus, productEnabled: Bool,
                effectiveDomain: AcceptedDateDomain) {
        self.capability = capability
        self.profile = profile
        self.contracts = contracts
        self.codeInstalled = codeInstalled
        self.verification = verification
        self.sourcePermission = sourcePermission
        self.productEnabled = productEnabled
        self.effectiveDomain = effectiveDomain
    }

    /// Selectable only when every dimension passes. An "installed" Boolean is never sufficient.
    public var isCallable: Bool {
        guard codeInstalled, productEnabled else { return false }
        guard case .accepted = verification else { return false }
        guard case .permitted = sourcePermission else { return false }
        return !effectiveDomain.intervals.isEmpty
    }
}

/// A research reference carries no callable adapter or output payload.
public struct ResearchFamilyReference: Sendable, Hashable {
    public let family: RegistryFamily
    public let researchContract: ContractID?
    public let sourceLocator: String
    /// Exact documented capability tokens from the pinned registry, in registry order.
    public let documentedCapabilities: [String]
    /// Exact explicitly-not-complete tokens from the pinned registry, in registry order.
    public let unresolvedGaps: [String]

    public init(family: RegistryFamily, researchContract: ContractID?, sourceLocator: String,
                documentedCapabilities: [String], unresolvedGaps: [String]) {
        self.family = family
        self.researchContract = researchContract
        self.sourceLocator = sourceLocator
        self.documentedCapabilities = documentedCapabilities
        self.unresolvedGaps = unresolvedGaps
    }
}

public struct CapabilityCatalogue: Sendable, Hashable {
    public let identity: CatalogueID
    /// All E1 descriptors, including installed-but-blocked operations.
    public let descriptors: [CapabilityDescriptor]
    public let researchReferences: [ResearchFamilyReference]

    public init(identity: CatalogueID, descriptors: [CapabilityDescriptor], researchReferences: [ResearchFamilyReference]) {
        self.identity = identity
        self.descriptors = descriptors
        self.researchReferences = researchReferences
    }

    public func descriptor(for capability: CalendarCapability, profile: ProfileID) -> CapabilityDescriptor? {
        descriptors.first { $0.capability == capability && $0.profile == profile }
    }
}
