import CryptoKit
import Foundation

/// Explicitly mixed traditions for the Celestial Almanac: Japanese +09 model 六曜 and daily
/// 九星, alongside the existing Chinese report's day branch and 28-mansion cycle.
/// These annotations do not change the report, its +08 lunar calendar or its activity advice.
public struct CelestialTraditions: Sendable, Hashable {
    public static let revision = "celestial-traditions-1"
    public static let japaneseCalendarProfile = "CAL-DE440S-REAL-UTC9-K37-DAY-1901-2100-v1"
    public static let nineStarMethod = "koyomi8-nearest-kinoene-240-day-intercalation-1"

    /// Nil outside 1901–2100 or if the authenticated Japanese context cannot load.
    public let kyureki: LunarDate?
    public let rokuyo: String?
    public let rokuyoRomanized: String?
    /// Japanese 日家九星 centre, 1…9. Never derived from the Chinese report's `flyStar`.
    public let dayNineStar: Int?
    /// The +09 lunar month borders a model conjunction within 120 seconds of midnight.
    public let kyurekiBoundarySensitive: Bool
    /// The adopted 2033–34 old-calendar numbering follows NAOJ 案1 (閏11月).
    public let kyurekiConventionNote: String?
    public let dayAnimal: String
    /// Four celestial guardians, selected by the report mansion's traditional seven-mansion sector.
    public let guardian: String
    /// Original full Chinese label from the existing report, e.g. 胃土雉.
    public let mansion: String
    public let mansionEnglish: String

    public init(report: AlmanacDayReport) {
        let japanese = JapaneseAlmanacContext.bundled?.values(on: report.gregorian)
        kyureki = japanese?.lunar
        if let lunar = japanese?.lunar {
            let index = (Int(lunar.month) + Int(lunar.day)) % 6
            rokuyo = ["大安", "赤口", "先勝", "友引", "先負", "仏滅"][index]
            rokuyoRomanized = ["Taian", "Shakkō", "Senshō", "Tomobiki", "Senbu", "Butsumetsu"][index]
        } else {
            rokuyo = nil
            rokuyoRomanized = nil
        }
        dayNineStar = japanese?.nineStar
        kyurekiBoundarySensitive = japanese?.sensitive ?? false
        kyurekiConventionNote = ("2033-08-25"..<"2034-03-20").contains(report.gregorian.label)
            ? "Japanese old-calendar numbering follows NAOJ proposal 1 (leap month 11)." : nil
        dayAnimal = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"][report.dayPillar.branchIndex]
        mansion = report.mansion
        let index = UpstreamTables.mansions.firstIndex(of: report.mansion)
        mansionEnglish = index.map { Self.mansionNames[$0] } ?? report.mansion
        // Table order is east, north, west, south: 角…箕 / 斗…壁 / 奎…參 / 井…軫.
        guardian = index.map { ["Azure Dragon", "Black Tortoise", "White Tiger", "Vermilion Bird"][$0 / 7] } ?? ""
    }

    private static let mansionNames = [
        "Horn", "Neck", "Root", "Room", "Heart", "Tail", "Winnowing Basket",
        "Dipper", "Ox", "Girl", "Emptiness", "Rooftop", "Encampment", "Wall",
        "Legs", "Bond", "Stomach", "Hairy Head", "Net", "Turtle Beak", "Three Stars",
        "Well", "Ghost", "Willow", "Star", "Extended Net", "Wings", "Chariot",
    ]
}

/// Authenticated finite +09 model inputs, extracted from the admitted regional calendar.
/// No hidden locale, current date, Foundation Chinese calendar or +08 fallback.
struct JapaneseAlmanacContext: Sendable {
    static let sha256 = "e35d9cfd5e57a130d2145f116f85f8e09c15ec0e1cbc9b1e7fbac6f1fce39d17"
    struct Month: Decodable, Sendable {
        let year: Int, month: Int, leap: Bool, start: String, length: Int
    }
    struct Solstice: Decodable, Sendable { let date: String, winter: Bool }
    struct Document: Decodable {
        let schema: String, sourceSHA256: String, sourceProfile: String
        let fixedOffsetSeconds: Int
        let months: [Month], solstices: [Solstice], sensitiveConjunctionDates: [String]
    }
    struct Pivot: Sendable { let date: GregorianDate, winter: Bool }
    struct Values { let lunar: LunarDate, nineStar: Int?, sensitive: Bool }
    let months: [(start: GregorianDate, row: Month)]
    let pivots: [Pivot]
    let sensitive: Set<String>

    static let bundled: Self? = {
        guard let data = DailyAlmanacResources.data("celestial-japanese-context") else { return nil }
        return Self(data: data)
    }()

    init?(data: Data) {
        guard SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == Self.sha256,
              let document = try? JSONDecoder().decode(Document.self, from: data),
              document.schema == "celestial-japanese-context-1",
              document.sourceSHA256 == "6c6798a78ea1b09c4658f5ad01719dc92bb30ac397ee00068403be60c0857fca",
              document.sourceProfile == CelestialTraditions.japaneseCalendarProfile,
              document.fixedOffsetSeconds == 32_400 else { return nil }
        do {
            months = try document.months.map { (try GregorianDate(label: $0.start), $0) }
            pivots = try document.solstices.map { row in
                let date = try GregorianDate(label: row.date)
                let index = try UpstreamCycles.dayPillarIndex(for: date, hour: 12)
                let pivot = try date.adding(days: Int64(index < 30 ? -index : 60 - index))
                return Pivot(date: pivot, winter: row.winter)
            }
        } catch { return nil }
        sensitive = Set(document.sensitiveConjunctionDates)
    }

    func values(on date: GregorianDate) -> Values? {
        guard DailyAlmanacReader.firstDate <= date, date <= DailyAlmanacReader.lastDate,
              let month = months.last(where: { $0.start <= date }) else { return nil }
        let day = Int(date.days(since: month.start)) + 1
        guard day <= month.row.length,
              let lunar = try? LunarDate(lunarYearStartingGregorianYear: month.row.year, month: month.row.month,
                                        isLeapMonth: month.row.leap, day: day) else { return nil }
        let end = try? month.start.adding(days: Int64(month.row.length))
        return Values(lunar: lunar, nineStar: nineStar(on: date),
                      sensitive: sensitive.contains(month.start.label) || end.map { sensitive.contains($0.label) } == true)
    }

    func nineStar(on date: GregorianDate) -> Int? {
        guard DailyAlmanacReader.firstDate <= date, date <= DailyAlmanacReader.lastDate,
              let index = pivots.lastIndex(where: { $0.date <= date }), index + 1 < pivots.count else { return nil }
        let start = pivots[index], end = pivots[index + 1]
        let span = end.date.days(since: start.date)
        guard span == 180 || span == 240 else { return nil }
        let offset = Int(date.days(since: start.date))
        let sign = start.winter ? 1 : -1
        let base = start.winter ? 1 : 9
        // In a 240-day interval, the last 60 are intercalary. At their midpoint repeat
        // the preceding star (summer 三碧 / winter 七赤), then reverse for the last 30.
        let value = span == 240 && offset >= 210
            ? base - 1 + sign * 209 - sign * (offset - 210)
            : base - 1 + sign * offset
        return ((value % 9) + 9) % 9 + 1
    }
}
