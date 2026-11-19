import AppIntents
import SwiftUI
import WidgetKit

struct WidgetThemeChoice: AppEntity {
    let fixedTheme: DailyTheme?
    var id: String { fixedTheme?.rawValue ?? "followApp" }

    static let followApp = Self(fixedTheme: nil)
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"
    static let defaultQuery = WidgetThemeQuery()

    var resolvedTheme: DailyTheme { fixedTheme ?? .current }
    var calendarLayout: Bool { fixedTheme?.opensWithCalendar ?? DailyTheme.savedCalendarLayout }

    var displayRepresentation: DisplayRepresentation {
        if let fixedTheme { return DisplayRepresentation(title: "\(fixedTheme.title)") }
        return DisplayRepresentation(title: "Follow App Theme")
    }
}

struct WidgetThemeQuery: EntityQuery {
    func suggestedEntities() async throws -> [WidgetThemeChoice] {
        [.followApp] + DailyTheme.allCases.map { WidgetThemeChoice(fixedTheme: $0) }
    }

    func entities(for identifiers: [String]) async throws -> [WidgetThemeChoice] {
        identifiers.compactMap { id in
            if id == WidgetThemeChoice.followApp.id { return .followApp }
            return DailyTheme(rawValue: id).map { WidgetThemeChoice(fixedTheme: $0) }
        }
    }

    func defaultResult() async -> WidgetThemeChoice? { .followApp }
}

struct AlmanacWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Daily Almanac"
    @Parameter(title: "Theme") var theme: WidgetThemeChoice?

    var selectedTheme: WidgetThemeChoice { theme ?? .followApp }

    init() { theme = .followApp }
}

struct DailyEntry: TimelineEntry {
    let date: Date
    let sheet: Sheet
    let theme: DailyTheme
    var calendarLayout = DailyTheme.savedCalendarLayout
}

struct DailyProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DailyEntry {
        DailyEntry(date: .now, sheet: Sheet(label: CivilDay.label(), loading: true), theme: .current)
    }
    func snapshot(for configuration: AlmanacWidgetConfiguration, in context: Context) async -> DailyEntry {
        let choice = configuration.selectedTheme
        return await entry(.now, theme: choice.resolvedTheme, calendarLayout: choice.calendarLayout)
    }

    func timeline(for configuration: AlmanacWidgetConfiguration, in context: Context) async -> Timeline<DailyEntry> {
        let entries = await entries(starting: .now, zone: .autoupdatingCurrent, choice: configuration.selectedTheme)
        return Timeline(entries: entries, policy: .after(entries[3].date))
    }

    func entries(starting start: Date, zone: TimeZone, choice: WidgetThemeChoice) async -> [DailyEntry] {
        let theme = choice.resolvedTheme
        let calendarLayout = choice.calendarLayout
        var instant = start
        var entries: [DailyEntry] = []
        for _ in 0..<5 {
            entries.append(await entry(instant, zone: zone, theme: theme, calendarLayout: calendarLayout))
            instant = CivilDay.nextMidnight(after: instant, zone: zone)
        }
        return entries
    }
    private func entry(_ instant: Date, zone: TimeZone = .autoupdatingCurrent, theme: DailyTheme,
                       calendarLayout: Bool) async -> DailyEntry {
        let label = CivilDay.label(instant, zone: zone)
        let page = try? await DayReader.load([label]).first
        return DailyEntry(date: instant, sheet: Sheet(label: label, page: page), theme: theme, calendarLayout: calendarLayout)
    }
}
