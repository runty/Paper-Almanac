// Faithful port of the pinned `Lunar` pipeline (cnlunar/lunar.py, commit 3f674fe), in source
// order: pillars → cycles → `get_AngelDemon()` with its seeds, additions, predicate tables,
// grade, conflict policy, ordered exception blocks and final cleanup. Upstream peculiarities are
// reproduced as-is and marked `PECULIARITY`; corrections belong to a separately named profile.

import TungShingCore

/// Typed evaluation outcomes that are not reports.
public enum AlmanacEvaluationError: Error, Sendable, Hashable {
    /// The context was built for a different hour than the profile evaluates at.
    case evaluationHourMismatch(context: Int, profile: Int)
    /// Upstream raises `IndexError` for this input; the profile is undefined on this date.
    case upstreamUndefined(UpstreamUndefinedReason)
    /// The context's term window does not contain the next term (contract violation).
    case nextTermUnavailable
    /// A corrected profile needs this year's 立春 date and the term window does not hold it (contract violation).
    case beginningOfSpringUnavailable
    case dateArithmetic
}

/// Why the upstream evaluator has no defined output.
public enum UpstreamUndefinedReason: Sendable, Hashable {
    /// `the60HeavenlyEarth[(lunarYear - 4) % 60 - _x]` with index 60 (lunar.py:286).
    case yearPillarIndexOutOfRange(Int)
    /// `chineseZodiacNameList[(lunarYear - 4) % 12 - _x]` with index 12 (lunar.py:134).
    /// PECULIARITY: in `beginningOfSpring` mode this happens between 立春 and lunar New Year when
    /// the previous lunar year ≡ 3 (mod 12), e.g. 2008-02-04…06 and 2032-02-04…10.
    case yearZodiacIndexOutOfRange(Int)
}

/// The almanac evaluator. Pure, synchronous and deterministic.
public enum AlmanacEvaluator {
    /// Evaluates one civil date under a profile.
    public static func evaluate(_ context: AlmanacDayContext, profile: AlmanacProfile) throws(AlmanacEvaluationError) -> AlmanacDayReport {
        guard Int(context.evaluationHour) == profile.evaluationHour else {
            throw .evaluationHourMismatch(context: Int(context.evaluationHour), profile: profile.evaluationHour)
        }
        var pipeline = Pipeline(context: context, profile: profile)
        return try pipeline.run()
    }
}

/// Insertion-ordered unique activity list (upstream lists are deduplicated through `set`).
struct ActivityBag: Sendable, Hashable {
    private(set) var items: [AlmanacActivity] = []
    private var members: Set<AlmanacActivity> = []

    init(_ items: [AlmanacActivity] = []) { for i in items { insert(i) } }

    func contains(_ a: AlmanacActivity) -> Bool { members.contains(a) }

    /// `rfAdd` / `+=`: returns the activities actually added.
    @discardableResult
    mutating func insert(_ a: AlmanacActivity) -> Bool {
        if !members.insert(a).inserted { return false }
        items.append(a)
        return true
    }

    @discardableResult
    mutating func insert(contentsOf list: [AlmanacActivity]) -> [AlmanacActivity] {
        var added: [AlmanacActivity] = []
        for a in list where insert(a) { added.append(a) }
        return added
    }

    /// `rfRemove` / `list.remove`: returns the activities actually removed.
    @discardableResult
    mutating func remove(_ list: [AlmanacActivity]) -> [AlmanacActivity] {
        var removed: [AlmanacActivity] = []
        for a in list where members.remove(a) != nil {
            if let idx = items.firstIndex(of: a) { items.remove(at: idx) }
            removed.append(a)
        }
        return removed
    }

    @discardableResult
    mutating func remove(_ a: AlmanacActivity) -> [AlmanacActivity] { remove([a]) }

    mutating func replace(with list: [AlmanacActivity]) { items = []; members = []; insert(contentsOf: list) }

    var isEmpty: Bool { items.isEmpty }
}

private struct Pipeline {
    let context: AlmanacDayContext
    let profile: AlmanacProfile

    init(context: AlmanacDayContext, profile: AlmanacProfile) {
        self.context = context
        self.profile = profile
    }

    /// The corrected profile's spring year: the Gregorian year, less one before this year's 立春 date (upstream index 2).
    /// 立春 falls in early February, so a date from March on is past it even when the ±60-day window no longer holds it.
    func springYear(of date: GregorianDate) throws(AlmanacEvaluationError) -> Int {
        if let lichun = context.solarTerms.first(where: { $0.upstreamIndex == 2 && $0.date.year == date.year }) {
            return Int(date.year) - (date < lichun.date ? 1 : 0)
        }
        guard date.month >= 3 else { throw .beginningOfSpringUnavailable }
        return Int(date.year)
    }

    mutating func run() throws(AlmanacEvaluationError) -> AlmanacDayReport {
        let date = context.gregorian
        let hour = Int(context.evaluationHour)
        let twohourNum = (hour + 1) / 2                                    // lunar.py:33

        // Lunar identity (supplied by the context; upstream computes it in get_lunarDateNum).
        let lunarYear = Int(context.lunar.lunarYearStartingGregorianYear)
        let lunarMonth = Int(context.lunar.month)
        let lunarDay = Int(context.lunar.day)
        let isLeapMonth = context.lunar.isLeapMonth
        let monthLength = Int(context.lunarMonthLength)
        let lunarMonthLong = monthLength >= 30                             // lunar.py:109–112
        let isBeforeLunarYear = lunarYear < Int(date.year)                 // spanDays < 0 (lunar.py:69)

        let lunarYearLabel = String(lunarYear).compactMap { ch -> String? in
            guard let digit = ch.wholeNumberValue, digit >= 0, digit < 10 else { return nil }
            return UpstreamTables.upperNumerals[digit]
        }.joined()                                                          // lunar.py:96–99
        var lunarMonthLabel = UpstreamTables.lunarMonthNames[floorMod(lunarMonth - 1, 12)]
        if isLeapMonth { lunarMonthLabel = "闰" + lunarMonthLabel }
        lunarMonthLabel += lunarMonthLong ? "大" : "小"                     // lunar.py:101–114
        let lunarDayLabel = UpstreamTables.lunarDayNames[floorMod(lunarDay - 1, 30)]

        let moonPhase: MoonPhaseLabel                                       // lunar.py:120–130
        if lunarDay - (lunarMonthLong ? 1 : 0) == 15 { moonPhase = .fullMoon }
        else if lunarDay == 1 { moonPhase = .newMoon }
        else if (7...8).contains(lunarDay) { moonPhase = .firstQuarter }
        else if (22...23).contains(lunarDay) { moonPhase = .lastQuarter }
        else { moonPhase = .none }

        // Solar terms (lunar.py:249–276). nextSolarNum counts this Gregorian year's terms on or
        // before the date; the contiguous window makes "latest term on or before" sufficient.
        let termsPassed: Int
        if let latest = context.latestTermOnOrBefore, Int(latest.date.year) == Int(date.year) {
            termsPassed = (latest.upstreamIndex + 1) % 24
        } else {
            termsPassed = 0
        }
        guard let nextTerm = context.nextTermAfter else { throw .nextTermUnavailable }
        let termOnDate = context.termOnDate
        let eastZodiac = UpstreamTables.eastZodiac[floorMod(nextTerm.upstreamIndex - 1, 24) / 2]   // lunar.py:280

        // Year label adjustment (lunar.py:64–92).
        // PECULIARITY: after 冬至 nextSolarNum wraps to 0, so `isBeforBeginningOfSpring` is also true
        // from 冬至 to 31 December and the rule year regresses by one in beginningOfSpring mode.
        let isBeforeBeginningOfSpring = termsPassed < 3
        var x = 0
        if profile.yearLabelMode == .beginningOfSpring {
            if profile.corrections.contains(.springYearFromLichunDay) {
                // CORRECTION (V1 R02 §4): the spring year from this year's 立春 date, a whole-day boundary.
                x = lunarYear - (try springYear(of: date))
            } else if isBeforeLunarYear {
                if !isBeforeBeginningOfSpring { x = -1 }
            } else if isBeforeBeginningOfSpring {
                x = 1
            }
        }

        // Pillars (lunar.py:284–310). Python negative indexing wraps −1 → 59; index 60/12 raise.
        let rawYear = floorMod(lunarYear - 4, 60) - x
        guard rawYear <= 59 else { throw .upstreamUndefined(.yearPillarIndexOutOfRange(rawYear)) }
        let yearPillar = SexagenaryPillar(index: rawYear)
        let rawZodiac = floorMod(lunarYear - 4, 12) - x
        // CORRECTION (V1 R02 §3): a corrected profile wraps the index; the source raises.
        guard rawZodiac <= 11 || profile.corrections.contains(.zodiacIndexWrap) else { throw .upstreamUndefined(.yearZodiacIndexOutOfRange(rawZodiac)) }
        let yearZodiac = UpstreamTables.zodiacAnimals[floorMod(rawZodiac, 12)]

        var nextNum = termsPassed
        if nextNum == 0 && Int(date.month) == 12 { nextNum = 24 }
        let apartNum = (nextNum + 1) / 2
        let monthPillar = SexagenaryPillar(index: floorMod((Int(date.year) - 2019) * 12 + apartNum, 60))

        guard let tomorrow = try? date.adding(days: 1) else { throw .dateArithmetic }
        let dayPillar = SexagenaryPillar(index: try UpstreamCycles.dayPillarIndex(for: date, hour: hour))   // 23:00 advance
        let dhen = dayPillar.index

        let hourBegin = (dayPillar.index * 12) % 60                          // lunar.py:314
        let hourPillars = (0..<13).map { SexagenaryPillar(index: hourBegin + $0) }
        let hourPillar = hourPillars[twohourNum % 12]

        let yearBranchIndex = yearPillar.branchIndex
        let monthBranchIndex = monthPillar.branchIndex
        let dayBranchIndex = dayPillar.branchIndex
        let yearStemIndex = yearPillar.stemIndex
        let dayStemIndex = dayPillar.stemIndex

        // Season (lunar.py:336–342)
        let monthPositionIndex = monthBranchIndex % 3
        let seasonIndex = floorMod(monthBranchIndex - 2, 12) / 3
        let monthPosition = UpstreamTables.monthPositions[monthPositionIndex]
        let season = UpstreamTables.seasons[seasonIndex]

        // Officer and day god (lunar.py:388–415)
        let men: Int
        switch profile.godType {
        case .cnlunar: men = floorMod(lunarMonth - 1 + 2, 12)
        case .eightChar: men = monthBranchIndex
        }
        let officerIndex = UpstreamCycles.officerIndex(monthBranchIndex: men, dayBranchIndex: dayBranchIndex)
        let officer = UpstreamTables.dayOfficers[officerIndex]
        let eclipticGodNum = UpstreamCycles.dayGodIndex(monthBranchIndex: men, dayBranchIndex: dayBranchIndex)
        let dayGod = UpstreamTables.dayGods[eclipticGodNum]
        let isYellowPath = UpstreamCycles.isYellowPath(dayGodIndex: eclipticGodNum)

        // Zodiac relations (lunar.py:136–144)
        let zodiac = UpstreamTables.zodiacAnimals
        let zodiacSix = zodiac[floorMod(25 - dayBranchIndex, 12)]
        let zodiacTriple = [zodiac[(dayBranchIndex + 4) % 12], zodiac[(dayBranchIndex + 8) % 12]]
        let zodiacClash = zodiac[dayBranchIndex] + "日冲" + zodiac[(dayBranchIndex + 6) % 12]

        let weekdayLabel = UpstreamTables.weekdays[(date.weekdaySunday0 + 6) % 7]   // lunar.py:151
        let starZodiac = UpstreamTables.starZodiacNames[
            UpstreamTables.starZodiacBoundaries.filter { ($0.month, $0.day) <= (Int(date.month), Int(date.day)) }.count % 12]

        // Mansion, 纳音, elements, nine stars, directions, fetal god, 彭祖, hour luck (lunar.py:418–465)
        let mansion = UpstreamTables.mansions[try UpstreamCycles.mansionIndex(for: date)]
        let nayin = UpstreamCycles.nayin(daySexagenaryIndex: dhen)
        let nayinElement = PyString.char(nayin, -1) ?? ""
        let fiveElements: [String] = [
            "天干", dayPillar.stem, "属" + UpstreamTables.heavenlyStemElements[dayStemIndex],
            "地支", dayPillar.branch, "属" + UpstreamTables.earthlyBranchElements[dayBranchIndex],
            "纳音", nayinElement, "属" + nayinElement,
            "廿八宿", PyString.char(mansion, 0) ?? "", "宿",
            "十二神", officer, "日",
        ]
        let flyStar = try UpstreamCycles.flyStar(for: date)
        let luckyDirections = UpstreamCycles.luckyDirections(stemIndex: dayStemIndex)
        let fetalGod = UpstreamCycles.fetalGod(daySexagenaryIndex: dhen)
        let pengTaboo = UpstreamCycles.pengTaboo(stemIndex: dayStemIndex, branchIndex: dayBranchIndex)
        let hourLuck = UpstreamCycles.hourLuck(daySexagenaryIndex: dhen)
        let meridian = UpstreamTables.meridians[twohourNum % 12]

        // Holidays (lunar.py:349–381)
        let legalHolidays = UpstreamHolidays.legalHolidays(todaySolarTerm: termOnDate?.upstreamName, date: date,
                                                           lunarMonth: lunarMonth, lunarDay: lunarDay)
        let otherHolidays = UpstreamHolidays.otherHolidays(date: date)
        let otherLunarHolidays = UpstreamHolidays.otherLunarHolidays(lunarMonth: lunarMonth, lunarDay: lunarDay)

        // ---- get_AngelDemon (lunar.py:614–1281) ----
        let thisYear = Int(date.year)
        let thisYearJue = context.solarTerms.filter { Int($0.date.year) == thisYear && $0.isSeasonStart }
        let thisYearLi = context.solarTerms.filter { Int($0.date.year) == thisYear && $0.isEquinoxOrSolstice }
        let tmd = (month: Int(tomorrow.month), day: Int(tomorrow.day))
        // twys (lunar.py:648): first this-year 立 on or after tomorrow. Without one inside the
        // window the upstream difference is provably outside range(0, 18) (see PHASE_2_ALMANAC.md).
        let earthKingDays: RuleOperand
        if let twys = thisYearJue.first(where: { $0.date >= tomorrow }) {
            let civil = Int(twys.date.days(since: date))
            earthKingDays = .integer(hour > 0 ? civil - 1 : civil)           // timedelta.days floors
        } else {
            earthKingDays = .absent
        }
        let env = RuleEnvironment(
            dayPillar: dayPillar.label, dayStem: dayPillar.stem, dayBranch: dayPillar.branch,
            dayBranchIndex: dayBranchIndex, daySexagenaryIndex: dhen, mansionInitial: PyString.char(mansion, 0) ?? "",
            officer: officer, seasonIndex: seasonIndex, yearStemIndex: yearStemIndex, yearBranchIndex: yearBranchIndex,
            lunarDay: lunarDay, lunarMonth: lunarMonth, monthBranchIndex: men, monthPosition: monthPosition,
            tomorrow: tmd,
            fourJueDates: thisYearJue.map { .monthDay(month: Int($0.date.month), day: Int($0.date.day)) },
            fourLiDates: thisYearLi.map { .monthDay(month: Int($0.date.month), day: Int($0.date.day)) },
            earthKingDays: earthKingDays)

        var good = ActivityBag()
        var bad = ActivityBag()

        // Officer seeds (lunar.py:631–635)
        let seeds = UpstreamActivityTables.officerThings[officerIndex]
        let officerSeed = AlmanacTraceEffect(rule: AlmanacRuleID(name: "officerThings[\(officer)]", file: AlmanacRuleID.tablesFile, line: 177),
                                             addedRecommendations: good.insert(contentsOf: seeds.recommends),
                                             addedAvoidances: bad.insert(contentsOf: seeds.avoids))

        // Stem/branch additions (lunar.py:667–670): `for i in day8CharThing: if i in d`
        var stemBranchAdditions: [AlmanacTraceEffect] = []
        for entry in UpstreamActivityTables.stemBranchThings where PyString.contains(dayPillar.label, entry.key) {
            stemBranchAdditions.append(AlmanacTraceEffect(
                rule: AlmanacRuleID(name: "day8CharThing[\(entry.key)]", file: AlmanacRuleID.tablesFile, line: 206),
                addedRecommendations: good.insert(contentsOf: entry.recommends),
                addedAvoidances: bad.insert(contentsOf: entry.avoids)))
        }

        // Seasonal and lunar-date additions (lunar.py:683–708)
        var seasonal: [AlmanacTraceEffect] = []
        let huntingOfficers = ["执", "危", "收"]
        if (4..<9).contains(termsPassed) && huntingOfficers.contains(officer) {
            seasonal.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "雨水后立夏前执危收日宜取鱼", line: 683),
                                               addedRecommendations: good.insert(contentsOf: [.quYu])))
        }
        if ((20..<24).contains(termsPassed) || (0..<3).contains(termsPassed)) && huntingOfficers.contains(officer) {
            seasonal.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "霜降后立春前执危收日宜畋猎", line: 695),
                                               addedRecommendations: good.insert(contentsOf: [.tianLie])))
        }
        // PECULIARITY: upstream tests `d in ['午', '申']` with the two-character pillar, which never
        // equals a bare branch; only the 危 officer part of this condition can fire.
        if ((21..<24).contains(termsPassed) || (0..<3).contains(termsPassed))
            && (officer == "危" || ["午", "申"].contains(dayPillar.label)) {
            seasonal.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "立冬后立春前危日宜伐木", line: 698),
                                               addedRecommendations: good.insert(contentsOf: [.faMu])))
        }
        if [1, 6, 15, 19, 21, 23].contains(lunarDay) {
            seasonal.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "每月一六十五十九廿一廿三忌整手足甲", line: 701),
                                               addedAvoidances: bad.insert(contentsOf: [.zhengShouZuJia])))
        }
        if [12, 15].contains(lunarDay) {
            seasonal.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "每月十二十五忌整容剃头", line: 704),
                                               addedAvoidances: bad.insert(contentsOf: [.zhengRong, .tiTou])))
        }
        if lunarDay == 15 || moonPhase != .none {
            seasonal.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "十五日朔弦望忌求医疗病", line: 707),
                                               addedAvoidances: bad.insert(contentsOf: [.qiuYiLiaoBing])))
        }
        let candidatesBeforeGods = AlmanacActivityLists(recommendations: good.items, avoidances: bad.items)

        // Predicate tables (lunar.py:1021–1041)
        var goodGods: [AlmanacGodName] = []
        var badGods: [AlmanacGodName] = []
        var matchedAngels: [AlmanacRuleMatch] = []
        var matchedDemons: [AlmanacRuleMatch] = []
        for table in [UpstreamAngelRules.rules, UpstreamDemonRules.rules] {
            for rule in table {
                if !profile.isYearGodDuty && rule.name.isYearGod { continue }   // lunar.py:1027–1029
                let (needle, container) = rule.operands(env)
                guard PyMembership.contains(needle, container) else { continue }
                let match = AlmanacRuleMatch(rule: rule.identity, name: rule.name, needle: needle, container: container,
                                             recommends: rule.recommends, avoids: rule.avoids)
                switch rule.kind {
                case .angel: goodGods.append(rule.name); matchedAngels.append(match)
                case .demon: badGods.append(rule.name); matchedDemons.append(match)
                }
                good.insert(contentsOf: rule.recommends)
                bad.insert(contentsOf: rule.avoids)
            }
        }
        let candidatesAfterGods = AlmanacActivityLists(recommendations: good.items, avoidances: bad.items)

        // Grade (lunar.py:468–612)
        let level = Pipeline.thingLevel(goodGods: goodGods, badGods: badGods, officer: officer, monthBranch: monthPillar.branch)
        let todayLevel = level.level
        let thingLevel = level.thingLevel
        let isDe = level.hasVirtue

        // Conflict policy (lunar.py:1046–1081)
        let conflict: AlmanacTraceEffect
        let overlap = good.items.filter { bad.contains($0) }
        switch thingLevel {
        case 3:
            let removedGood = good.items, removedBad = bad.items
            good.replace(with: [.nothingSuitable])
            bad.replace(with: [.nothingSuitable])
            conflict = AlmanacTraceEffect(rule: .nothingGood,
                                          addedRecommendations: [.nothingSuitable], removedRecommendations: removedGood,
                                          addedAvoidances: [.nothingSuitable], removedAvoidances: removedBad, note: "诸事皆忌")
        case 2:
            conflict = AlmanacTraceEffect(rule: AlmanacRuleID(name: "badOppressGood", line: 1053),
                                          removedRecommendations: good.remove(overlap), note: "从忌不从宜")
        case 1:
            conflict = AlmanacTraceEffect(rule: AlmanacRuleID(name: "badDrewGood", line: 1046),
                                          removedRecommendations: good.remove(overlap), removedAvoidances: bad.remove(overlap), note: "从宜亦从忌")
        default:
            conflict = AlmanacTraceEffect(rule: AlmanacRuleID(name: "goodOppressBad", line: 1059),
                                          removedAvoidances: bad.remove(overlap), note: "从宜不从忌")
        }

        // 遇德犹忌 (lunar.py:1089–1097): avoid lists of angel[:6] for matched virtues.
        var deIsBadThing = ActivityBag()
        if isDe {
            let virtueRules = Array(UpstreamAngelRules.rules.prefix(6))
            for name in goodGods {
                if let rule = virtueRules.first(where: { $0.name == name }) { deIsBadThing.insert(contentsOf: rule.avoids) }
            }
        }
        let deList = deIsBadThing.items

        // Ordered exception blocks (lunar.py:1099–1260)
        var exceptions: [AlmanacTraceEffect] = []
        if thingLevel != 3 {
            if good.contains(.xuanZhengShi) && good.contains(.buZhengShi) {
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "宜宣政事布政事只注宣政事", line: 1101),
                                                     removedRecommendations: good.remove(.buZhengShi)))
            }
            if good.contains(.yingJianGongShi) && good.contains(.xiuGongShi) {
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "宜营建宫室修宫室只注营建宫室", line: 1104),
                                                     removedRecommendations: good.remove(.xiuGongShi)))
            }
            var maxPower: [AlmanacGodName] = [.yueDeHe, .tianDeHe, .tianShe, .tianYuan, .yueEn, .siXiang, .shiDe]
            if profile.isYearGodDuty { maxPower = [.suiDeHe] + maxPower }
            let isDeSheEnSixiang = goodGods.contains { maxPower.contains($0) }
            if isDeSheEnSixiang && thingLevel != 2 {
                let removed = bad.remove([.jinRenKou, .anChuang, .jingLuo, .yunNiang, .kaiShi, .liQuanJiaoYi, .naCai, .kaiCangKu, .chuHuoCai])
                let added = bad.insert(contentsOf: deList)
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "德合赦愿月恩四相时德不注忌进人口等", line: 1119),
                                                     addedAvoidances: added, removedAvoidances: removed))
            }
            if badGods.contains(.tianGou) || PyString.contains(dayPillar.label, "寅") {
                let added = bad.insert(contentsOf: [.jiSi])
                let removed = good.remove([.jiSi]) + good.remove([.qiuFu, .qiSi])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "天狗寅日忌祭祀不注宜求福祈嗣", line: 1130),
                                                     removedRecommendations: removed, addedAvoidances: added))
            }
            if PyString.contains(dayPillar.label, "卯") {
                let added = bad.insert(contentsOf: [.chuanJing])
                let removed = good.remove([.chuanJing]) + good.remove([.kaiQu])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "卯日忌穿井不注宜开渠", line: 1136),
                                                     removedRecommendations: removed, addedAvoidances: added))
            }
            if PyString.contains(dayPillar.label, "壬") {
                let added = bad.insert(contentsOf: [.kaiQu])
                let removed = good.remove([.kaiQu]) + good.remove([.chuanJing])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "壬日忌开渠不注宜穿井", line: 1141),
                                                     removedRecommendations: removed, addedAvoidances: added))
            }
            if PyString.contains(dayPillar.label, "巳") {
                let added = bad.insert(contentsOf: [.chuXing])
                let removed = good.remove([.chuXing]) + good.remove([.chuShi, .qianShi])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "巳日忌出行不注宜出师遣使", line: 1147),
                                                     removedRecommendations: removed, addedAvoidances: added))
            }
            if PyString.contains(dayPillar.label, "酉") {
                let added = bad.insert(contentsOf: [.yanHui])
                let removed = good.remove([.yanHui]) + good.remove([.qingCi, .shangHe])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "酉日忌宴会不注宜庆赐赏贺", line: 1153),
                                                     removedRecommendations: removed, addedAvoidances: added))
            }
            if PyString.contains(dayPillar.label, "丁") {
                let added = bad.insert(contentsOf: [.tiTou])
                let removed = good.remove([.tiTou]) + good.remove([.zhengRong])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "丁日忌剃头不注宜整容", line: 1159),
                                                     removedRecommendations: removed, addedAvoidances: added))
            }
            if todayLevel == 0 && thingLevel == 0 {
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "吉足胜凶遇德犹忌仍注忌", line: 1165),
                                                     addedAvoidances: bad.insert(contentsOf: deList)))
            }
            if todayLevel == 1 {
                var added = bad.insert(contentsOf: deList)
                var removed: [AlmanacActivity] = []
                if !bad.contains(.qiFu) { removed += bad.remove([.qiuSi]) }
                if !bad.contains(.jieHunYin) && !isDe { removed += bad.remove([.guanDai, .naCaiWenMing, .jiaQu, .jinRenKou]) }
                if !bad.contains(.jiaQu) && !isDe {
                    if goodGods.contains(.buJiang) {
                        // 遇不将而不注忌嫁娶者，亦仍注忌 (pass)
                    } else {
                        removed += bad.remove([.guanDai, .naCaiWenMing, .jieHunYin, .jinRenKou, .banYi, .anChuang])
                    }
                }
                added = UpstreamActivityTables.sortedForOutput(added)
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "吉凶相抵不注宜亦不注忌", line: 1168),
                                                     addedAvoidances: added, removedAvoidances: removed))
            }
            if PyString.contains(dayPillar.label, "亥") {
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "亥日仍注忌嫁娶【未妥善解决】", line: 1184),
                                                     addedAvoidances: bad.insert(contentsOf: [.jiaQu])))
            }
            if todayLevel == 1 && !isDe {
                var removed: [AlmanacActivity] = []
                if !bad.contains(.banYi) { removed += bad.remove([.anChuang]) }
                if !bad.contains(.anChuang) { removed += bad.remove([.banYi]) }
                if !bad.contains(.jieChu) { removed += bad.remove([.zhengRong, .tiTou, .zhengShouZuJia]) }
                if !bad.contains(.xiuZao) || !bad.contains(.shuZhuShangLiang) {
                    removed += bad.remove([.xiuGongShi, .shanChengGuo, .zhengShouZuJia, .zhuTi, .xiuCangKu, .guZhu, .shanGai, .xiuZhiChanShi,
                                           .kaiQuChuanJing, .anDuiWei, .buYuanSaiXue, .xiuShiYuanQiang, .pingZhiDaoTu, .poWuHuaiYuan])
                }
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "吉凶相抵不注忌搬移安床解除修造", line: 1187),
                                                     removedAvoidances: removed))
            }
            if todayLevel == 1 {
                var removed: [AlmanacActivity] = []
                if !bad.contains(.kaiShi) { removed += bad.remove([.liQuanJiaoYi, .naCai, .kaiCangKu, .chuHuoCai]) }
                if !bad.contains(.naCai) { removed += bad.remove([.liQuanJiaoYi, .kaiShi]) }
                if !bad.contains(.liQuanJiaoYi) { removed += bad.remove([.naCai, .kaiShi, .kaiCangKu, .chuHuoCai]) }
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "吉凶相抵不注忌开市立券交易纳财", line: 1202),
                                                     removedAvoidances: removed))
            }
            if todayLevel == 1 {
                var removed: [AlmanacActivity] = []
                if !bad.contains(.muYang) { removed += bad.remove([.naChu]) }
                if !bad.contains(.naChu) { removed += bad.remove([.muYang]) }
                if good.contains(.anZang) { removed += bad.remove([.qiCuan]) }
                if good.contains(.qiCuan) { removed += bad.remove([.anZang]) }
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "吉凶相抵不注忌牧养纳畜安葬启攒", line: 1212),
                                                     removedAvoidances: removed))
            }
            if bad.contains(.zhaoMingGongQing) || bad.contains(.zhaoXian) {
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "忌诏命公卿招贤不注宜施恩举正直", line: 1223),
                                                     removedRecommendations: good.remove([.shiEn, .juZhengZhi])))
            }
            if bad.contains(.shiEn) || bad.contains(.juZhengZhi) {
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "忌施恩举正直不注宜诏命公卿招贤", line: 1226),
                                                     removedRecommendations: good.remove([.zhaoMingGongQing, .zhaoXian])))
            }
            if good.contains(.xuanZhengShi) && badGods.contains(.wangWang) {
                let removed = good.remove(.xuanZhengShi)
                let added = good.insert(contentsOf: [.buZhengShi])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "宜宣政事遇往亡改宣为布", line: 1229),
                                                     addedRecommendations: added, removedRecommendations: removed))
            }
            if badGods.contains(.yueYan) {
                var removedGood = good.remove([.banZhao, .shiEn, .zhaoXian, .juZhengZhi, .xuanZhengShi])
                let addedGood = good.insert(contentsOf: [.buZhengShi])
                let addedBad = bad.insert(contentsOf: [.buYuan])
                if badGods.contains(.tuFu) || badGods.contains(.tuFuSymbol) || badGods.contains(.diNang) {
                    removedGood += good.remove([.saiXue])
                }
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "月厌不注宜颁诏施恩招贤举正直宣政事", line: 1233),
                                                     addedRecommendations: addedGood, removedRecommendations: removedGood,
                                                     addedAvoidances: addedBad))
            }
            if PyString.contains(officer, "开") {
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "开日不注宜破土安葬启攒", line: 1241),
                                                     removedRecommendations: good.remove([.poTu, .anZang, .qiCuan])))
            }
            if badGods.contains(.siJi) || badGods.contains(.siQiong) {
                let added = bad.insert(contentsOf: [.anZang])
                let removed = good.remove([.poTu, .qiCuan])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "四忌四穷只忌安葬", line: 1246),
                                                     removedRecommendations: removed, addedAvoidances: added))
            }
            if goodGods.contains(.mingFei) || goodGods.contains(.mingFeiDui) {
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "鸣吠鸣吠对不注宜破土启攒", line: 1251),
                                                     removedRecommendations: good.remove([.poTu, .qiCuan])))
            }
            let virtueMeeting = ["空", "甲戌", "空", "丙申", "空", "甲子", "戊申", "庚辰", "辛卯", "甲子", "空", "甲子"]
            if PyString.contains(dayPillar.label, RuleText.pick(virtueMeeting, lunarMonth - 1)) {
                let removed = bad.items
                bad.replace(with: [.nothingAvoided])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "德合与赦愿所会之辰诸事不忌", line: 1256),
                                                     addedAvoidances: [.nothingAvoided], removedAvoidances: removed))
            }
            let hasHe = goodGods.contains { [.suiDeHe, .yueDeHe, .tianDeHe].contains($0) }
            let hasSheYuan = goodGods.contains { [.tianShe, .tianYuan].contains($0) }
            if hasHe && hasSheYuan {
                let hadSentinelOnly = bad.items == [.nothingAvoided]
                let removed = bad.items.filter { $0 != .nothingAvoided }
                bad.replace(with: [.nothingAvoided])
                exceptions.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "德合遇赦愿诸事不忌", line: 1258),
                                                     addedAvoidances: hadSentinelOnly ? [] : [.nothingAvoided],
                                                     removedAvoidances: removed))
            }
        }

        // Final cleanup (lunar.py:1263–1280)
        var cleanup: [AlmanacTraceEffect] = []
        let rmThing = bad.items.filter { good.contains($0) }
        if rmThing.count == 1, PyString.contains(rmThing[0].rawValue, "诸事") {
            cleanup.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "忌不注宜（诸事哨兵保留）", line: 1267), note: "pass"))
        } else {
            cleanup.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "忌不注宜", line: 1270), removedRecommendations: good.remove(rmThing)))
        }
        if bad.isEmpty {
            bad.insert(.nothingAvoided)
            cleanup.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "忌为空注诸事不忌", line: 1273), addedAvoidances: [.nothingAvoided]))
        }
        if good.isEmpty {
            good.insert(.nothingSuitable)
            cleanup.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "宜为空注诸事不宜", line: 1275), addedRecommendations: [.nothingSuitable]))
        }
        cleanup.append(AlmanacTraceEffect(rule: AlmanacRuleID(name: "sortCollation（并列项按码位）", line: 1279), note: "stable sort; ties by code point"))
        let recommendations = UpstreamActivityTables.sortedForOutput(good.items)
        let avoidances = UpstreamActivityTables.sortedForOutput(bad.items)

        let profileDigest = (try? profile.digest()) ?? ""
        let evidence = Pipeline.evidence(profile: profile, digest: profileDigest, context: context)
        let trace = AlmanacTrace(
            officerSeed: officerSeed, stemBranchAdditions: stemBranchAdditions, seasonalAdditions: seasonal,
            candidatesBeforeGods: candidatesBeforeGods, matchedAngels: matchedAngels, matchedDemons: matchedDemons,
            candidatesAfterGods: candidatesAfterGods, level: level, conflictResolution: conflict,
            virtueRetainedAvoidances: UpstreamActivityTables.sortedForOutput(deList), exceptions: exceptions,
            finalCleanup: cleanup, evidence: evidence)

        return AlmanacDayReport(
            profile: profile.identity, profileDigest: profileDigest, gregorian: date, evaluationHour: hour,
            lunar: context.lunar, lunarMonthLength: monthLength, lunarYearLabel: lunarYearLabel, lunarMonthLabel: lunarMonthLabel,
            lunarDayLabel: lunarDayLabel, weekdayLabel: weekdayLabel, moonPhase: moonPhase,
            termOnDate: termOnDate, nextTerm: nextTerm, termsPassedThisYear: termsPassed, eastZodiac: eastZodiac, starZodiac: starZodiac,
            yearPillar: yearPillar, monthPillar: monthPillar, dayPillar: dayPillar, hourPillar: hourPillar, hourPillars: hourPillars,
            yearLabelAdjustment: x, yearZodiac: yearZodiac, zodiacClash: zodiacClash, zodiacSixHarmony: zodiacSix,
            zodiacTripleHarmony: zodiacTriple,
            monthPositionIndex: monthPositionIndex, seasonIndex: seasonIndex, monthPosition: monthPosition, season: season,
            seasonLabel: monthPosition + season,
            officer: officer, dayGod: dayGod, isYellowPath: isYellowPath, mansion: mansion, nayin: nayin, fiveElements: fiveElements,
            flyStar: flyStar, luckyDirections: luckyDirections, fetalGod: fetalGod, pengTaboo: pengTaboo,
            hourLuckIsInauspicious: hourLuck, meridian: meridian,
            legalHolidays: legalHolidays, otherHolidays: otherHolidays, otherLunarHolidays: otherLunarHolidays,
            level: level, goodGodNames: goodGods, badGodNames: badGods, recommendations: recommendations, avoidances: avoidances,
            trace: trace)
    }

    /// `getTodayThingLevel` (lunar.py:468–612).
    static func thingLevel(goodGods: [AlmanacGodName], badGods: [AlmanacGodName], officer: String, monthBranch: String) -> AlmanacLevelDecision {
        let allNames = goodGods.map(\.rawValue) + badGods.map(\.rawValue) + [officer + "日"]
        var l = -1
        var hits: [AlmanacLevelTableHit] = []
        for name in allNames {
            guard let entry = UpstreamLevelTable.entries.first(where: { $0.key == name }) else { continue }
            for row in entry.rows where PyString.contains(row.monthBranches, monthBranch) {
                for companion in row.companions {
                    if allNames.contains(companion) && row.level > l {
                        l = row.level
                        hits.append(AlmanacLevelTableHit(key: name, row: row, matchedCompanion: companion))
                        break
                    }
                }
            }
        }
        let isDe = goodGods.contains { UpstreamLevelTable.virtueNames.contains($0) }
        let thingLevel: Int
        switch l {
        case 5: thingLevel = 3
        case 4: thingLevel = isDe ? 2 : 3
        case 3: thingLevel = isDe ? 1 : 2
        case 2: thingLevel = isDe ? 0 : 2
        case 1: thingLevel = isDe ? 0 : 1
        case 0: thingLevel = 0
        default: thingLevel = 1
        }
        return AlmanacLevelDecision(level: l, levelName: UpstreamLevelTable.levelName(l), hits: hits, hasVirtue: isDe,
                                    thingLevel: thingLevel, thingLevelName: UpstreamLevelTable.thingLevelNames[thingLevel])
    }

    static func evidence(profile: AlmanacProfile, digest: String, context: AlmanacDayContext) -> [AlmanacEvidence] {
        func make(_ id: String, _ role: String, _ locator: String) -> AlmanacEvidence? {
            guard let identity = try? EvidenceID(id) else { return nil }
            return AlmanacEvidence(identity: identity, role: role, locator: locator)
        }
        let window = "\(context.solarTerms.first?.date.label ?? "-")…\(context.solarTerms.last?.date.label ?? "-")"
        let lunar = "\(context.lunar.lunarYearStartingGregorianYear)/\(context.lunar.month)\(context.lunar.isLeapMonth ? "L" : "")/\(context.lunar.day) len=\(context.lunarMonthLength)"
        return [
            make("almanac.upstream.source", "software-fidelity-source", "\(profile.source.repository)@\(profile.source.commit) (\(profile.source.license))"),
            make("almanac.profile", "profile", "\(profile.identity.value) \(digest)"),
            make("almanac.port", "port-revision", profile.portRevision),
            make("almanac.context.lunar", "calendar-fact", "E1-supplied lunar identity \(lunar)"),
            make("almanac.context.solarTerms", "calendar-fact", "E1-supplied term window \(window)"),
        ].compactMap { $0 }
    }
}
