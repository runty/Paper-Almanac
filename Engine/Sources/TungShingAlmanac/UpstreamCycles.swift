// Small pure functions for the upstream day cycles, factored out of the pipeline so table
// tests can exhaust them (60 pillars, 12×12 officers/gods, 22 彭祖 rows, 60 fetal gods,
// 60 hour masks, 10 direction rows) independently of a full evaluation.

import TungShingCore

public enum UpstreamCycles {
    /// Upstream day-pillar anchor: 2019-01-29 is 丙寅 (lunar.py:304–305).
    public static let dayPillarAnchorIndex = 2

    /// `get_day8Char` (lunar.py:303–310): sexagenary index for a civil date at a wall-clock hour.
    /// At 23:00 (`twohourNum == 12`) the index advances by one.
    public static func dayPillarIndex(for date: GregorianDate, hour: Int) throws(AlmanacEvaluationError) -> Int {
        guard let anchor = try? GregorianDate(year: 2019, month: 1, day: 29) else { throw .dateArithmetic }
        let twohourNum = (hour + 1) / 2
        let base = dayPillarAnchorIndex + (twohourNum == 12 ? 1 : 0)
        return floorMod(Int(date.days(since: anchor)) + base, 60)
    }

    /// `get_today12DayOfficer` (lunar.py:403–406): officer index from rule-month and day branches.
    public static func officerIndex(monthBranchIndex: Int, dayBranchIndex: Int) -> Int {
        floorMod(dayBranchIndex - floorMod(monthBranchIndex, 12), 12)
    }

    /// `get_today12DayOfficer` (lunar.py:412–413): 青龙-cycle god index.
    public static func dayGodIndex(monthBranchIndex: Int, dayBranchIndex: Int) -> Int {
        floorMod(dayBranchIndex - UpstreamTables.eclipticStartByMonthBranch[floorMod(monthBranchIndex, 12)], 12)
    }

    /// `dayName == '黄道日'` (lunar.py:414).
    public static func isYellowPath(dayGodIndex: Int) -> Bool {
        UpstreamTables.yellowPathGodIndices.contains(dayGodIndex)
    }

    /// `get_nayin` (lunar.py:422).
    public static func nayin(daySexagenaryIndex: Int) -> String {
        UpstreamTables.nayin[floorMod(daySexagenaryIndex, 60) / 2]
    }

    /// `get_fetalGod` (lunar.py:454).
    public static func fetalGod(daySexagenaryIndex: Int) -> String {
        UpstreamTables.fetalGods[floorMod(daySexagenaryIndex, 60)]
    }

    /// `get_pengTaboo(long=9, delimit=',')` (lunar.py:384–385).
    public static func pengTaboo(stemIndex: Int, branchIndex: Int) -> String {
        PyString.prefix(UpstreamTables.pengTaboo[floorMod(stemIndex, 10)], 9) + ","
            + PyString.prefix(UpstreamTables.pengTaboo[floorMod(branchIndex, 12) + 10], 9)
    }

    /// `get_luckyGodsDirection` (lunar.py:443–452).
    public static func luckyDirections(stemIndex: Int) -> [String] {
        let s = floorMod(stemIndex, 10)
        func direction(_ table: [String], _ label: String) -> String {
            let idx = UpstreamTables.trigrams.firstIndex(of: table[s]) ?? 0
            return label + UpstreamTables.directions[idx]
        }
        return [
            direction(UpstreamTables.luckyGodDirection, "喜神"),
            direction(UpstreamTables.wealthGodDirection, "财神"),
            direction(UpstreamTables.mascotGodDirection, "福神"),
            direction(UpstreamTables.sunNobleDirection, "阳贵"),
            direction(UpstreamTables.moonNobleDirection, "阴贵"),
        ]
    }

    /// `get_twohourLuckyList` (lunar.py:458–465): 13 entries, `true` = 凶.
    public static func hourLuck(daySexagenaryIndex: Int) -> [Bool] {
        let today = floorMod(daySexagenaryIndex, 60)
        func bits(_ mask: UInt16) -> [Bool] { (1...12).map { mask & (1 << UInt16(12 - $0)) != 0 } }
        let all = bits(UpstreamTables.doubleHourLuckMasks[today]) + bits(UpstreamTables.doubleHourLuckMasks[(today + 1) % 60])
        return Array(all.prefix(13))
    }

    /// `get_the9FlyStar` (lunar.py:437–441).
    public static func flyStar(for date: GregorianDate) throws(AlmanacEvaluationError) -> String {
        guard let anchor = try? GregorianDate(year: 2019, month: 1, day: 17) else { throw .dateArithmetic }
        let apart = Int(date.days(since: anchor))
        return UpstreamTables.flyStarStart.map { String(floorMod($0 - 1 - apart, 9) + 1) }.joined()
    }

    /// `get_the28Stars` (lunar.py:418–420): mansion index for a civil date (not hour-adjusted).
    public static func mansionIndex(for date: GregorianDate) throws(AlmanacEvaluationError) -> Int {
        guard let anchor = try? GregorianDate(year: 2019, month: 1, day: 17) else { throw .dateArithmetic }
        return floorMod(Int(date.days(since: anchor)), 28)
    }
}
