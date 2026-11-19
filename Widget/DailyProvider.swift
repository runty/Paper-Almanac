import SwiftUI
import WidgetKit

struct DailyEntry: TimelineEntry {
    let date: Date
    let sheet: Sheet
    let theme: DailyTheme
    var calendarLayout = DailyTheme.savedCalendarLayout
}

struct DailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyEntry {
        DailyEntry(date: .now, sheet: Sheet(label: CivilDay.label(), loading: true), theme: .current)
    }
    func getSnapshot(in context: Context, completion: @escaping (DailyEntry) -> Void) {
        Task { completion(await entry(.now, theme: .current)) }
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
        Task {
            let entries = await entries(starting: Date.now, zone: .autoupdatingCurrent, theme: .current)
            completion(Timeline(entries: entries, policy: .after(entries[3].date)))
        }
    }
    func entries(starting start: Date, zone: TimeZone, theme: DailyTheme) async -> [DailyEntry] {
        let calendarLayout = DailyTheme.savedCalendarLayout
        var instant = start
        var entries: [DailyEntry] = []
        for _ in 0..<5 {
            entries.append(await entry(instant, zone: zone, theme: theme, calendarLayout: calendarLayout))
            instant = CivilDay.nextMidnight(after: instant, zone: zone)
        }
        return entries
    }
    private func entry(_ instant: Date, zone: TimeZone = .autoupdatingCurrent, theme: DailyTheme,
                       calendarLayout: Bool = DailyTheme.savedCalendarLayout) async -> DailyEntry {
        let label = CivilDay.label(instant, zone: zone)
        let page = try? await DayReader.load([label]).first
        return DailyEntry(date: instant, sheet: Sheet(label: label, page: page), theme: theme, calendarLayout: calendarLayout)
    }
}
