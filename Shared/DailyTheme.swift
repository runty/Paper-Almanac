import SwiftUI

enum DailyTheme: String, CaseIterable, Identifiable {
    case tungShing, celestialAlmanac, editorialDay, tongsheng, huangli, fuji, moon, tsukigoyomi, nihon, kinun, illyeok, lichViet
    case showa, koyomi, twinPillars = "deskBlock"

    init?(rawValue: String) {
        if rawValue == "almanacColumns" {
            self = .twinPillars
        } else if let theme = Self.allCases.first(where: { $0.rawValue == rawValue }) {
            self = theme
        } else {
            return nil
        }
    }

    var id: Self { self }
    static let calendarLayoutKey = "print.himekuriCalendar"
    static var savedCalendarLayout: Bool { defaults.bool(forKey: calendarLayoutKey) }
    static let key = "print.theme"
    static var defaults: UserDefaults {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "PaperAlmanacAppGroup") as? String,
              FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) != nil,
              let shared = UserDefaults(suiteName: group) else { return .standard }
        return shared
    }
    static var current: Self { defaults.string(forKey: key).flatMap(Self.init(rawValue:)) ?? .tungShing }
    var opensWithCalendar: Bool {
        switch self {
        case .showa, .koyomi: true
        default: false
        }
    }

    var original: PageTheme? {
        switch self {
        case .showa: .showa
        case .koyomi: .koyomi
        case .huangli: .huangli
        case .tongsheng: .tongsheng
        default: nil
        }
    }
    /// Apply the weekday ink to the first character of a Do/Avoid heading.
    func activityHeading(_ label: String, onDarkPaper: Bool = false) -> Text {
        guard self == .twinPillars else { return Text(verbatim: label) }
        var text = AttributedString(label)
        text[..<text.characters.prefix(1).endIndex].foregroundColor = Self.pillarInk(onDarkPaper: onDarkPaper)
        return Text(text)
    }

    static func pillarInk(onDarkPaper: Bool = false) -> Color {
        onDarkPaper ? Color(red: 1, green: 0.65, blue: 0.56) : ResearchFace.vermilion
    }

    var blockTopPad: CGFloat { self == .kinun ? Kinun.headerHeight + 2 : Metrics.blockTopPad }

    var offersActivityLists: Bool { self != .tsukigoyomi && self != .fuji && self != .moon && self != .kinun && self != .nihon && self != .illyeok && self != .lichViet }

    var widgetPaper: Color {
        if self == .tsukigoyomi { return TsukigoyomiFace.paper }
        if self == .lichViet { return LichVietFace.paper }
        if self == .illyeok { return IllyeokFace.paper }
        if self == .kinun { return Kinun.paper }
        if self == .nihon { return NihonFace.paper }
        if self == .moon { return MoonFace.paper }
        if self == .fuji { return FujiFace.paper }
        if self == .celestialAlmanac { return CelestialFace.paper }
        return original?.paper ?? Color(red: 1, green: 0.994, blue: 0.98)
    }
    var title: String {
        switch self {
        case .tungShing: "Yut Lik"
        case .celestialAlmanac: "Celestial Almanac"
        case .fuji: "Fuji"
        case .tsukigoyomi: "Tsukigoyomi"
        case .moon: "Tsukikage"
        case .kinun: "Kin’un"
        case .nihon: "Rekichū"
        case .lichViet: "Lịch Việt"
        case .illyeok: "Illyeok"
        case .twinPillars: "Twin Pillars"
        case .editorialDay: "Editorial Day"
        default: original!.title
        }
    }
}

struct Sheet {
    let label: String
    var page: PrintedDay?
    var loading = false
    var skySite = SkySite.saved
    func description(for theme: DailyTheme, calendarLayout: Bool) -> String {
        if theme == .tungShing, let page, let proverb = ChineseProverb.on(page.date) {
            return description + " Chinese proverb. " + proverb.english
        }
        if theme == .tsukigoyomi, let page { return TsukigoyomiReading(page).summary }
        if theme == .lichViet, let page { return LichVietReading(page).summary }
        if theme == .illyeok, let page { return IllyeokReading(page).summary }
        if theme == .kinun, let page { return Kinun.summary(NihonReading(page)) }
        if theme == .nihon, let page { return NihonReading(page).summary }
        if theme == .moon, let page { return MoonReading(page, site: skySite).summary }
        if theme == .fuji, let page { return FujiReading(page).summary }
        if theme == .celestialAlmanac, let page { return label + ". " + CelestialReading(page).summary }
        guard calendarLayout, let original = theme.original, let page else { return description }
        let caption = DayInfo(page: page).calendarProverb(for: original)
        return [label, "Month calendar", caption].compactMap { $0 }.joined(separator: ". ")
    }

    var description: String {
        guard let page else { return label + (loading ? ", loading" : ", almanac unavailable") }
        return "\(label). Do: \(page.recommended.lines.joined(separator: ", ")). Avoid: \(page.avoided.lines.joined(separator: ", "))."
    }
}
