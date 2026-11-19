import SwiftUI

struct ActivityPanel: View {
    @Environment(\.isWidgetSheet) private var isWidgetSheet
    let page: PrintedDay
    var design: Font.Design = .default
    var theme: DailyTheme? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            group("宜  DO", .recommended, page.recommended)
            group("忌  AVOID", .avoided, page.avoided)
        }.padding(.horizontal, 8)
    }
    private func group(_ title: String, _ side: ActivityPreference.Side, _ reading: Reading) -> some View {
        VStack(spacing: 3) {
            (theme?.activityHeading(title) ?? Text(verbatim: title)).font(.system(size: 11, weight: .bold, design: design))
            Text(verbatim: reading.lines.joined(separator: " · ")).font(.system(size: isWidgetSheet ? 11 : 9, design: design))
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity)
            .activityLink(day: page.date.label, side: side)
    }
}
