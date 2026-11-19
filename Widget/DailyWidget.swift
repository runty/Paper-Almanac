import SwiftUI
import WidgetKit

private struct FamilyFace: View {
    let entry: DailyEntry
    @Environment(\.widgetFamily) var family
    var body: some View { WidgetFace(entry: entry, family: family) }
}

@main struct TungShingWidget: Widget {
    private var families: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .systemExtraLargePortrait]
        #else
        [.systemSmall, .systemMedium, .systemLarge]
        #endif
    }
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TungShingDailyWidget", provider: DailyProvider()) { FamilyFace(entry: $0) }
            .configurationDisplayName("Daily Almanac")
            .description(Text(verbatim: AppIdentity.subtitle))
            .supportedFamilies(families).contentMarginsDisabled()
    }
}
