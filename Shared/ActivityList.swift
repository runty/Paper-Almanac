import SwiftUI

private struct ActivityListPresenter: ViewModifier {
    @ObservedObject var store: PadStore
    let theme: DailyTheme
    func body(content: Content) -> some View {
        content.environment(\.activityListSelection, $store.activitySide)
            #if os(macOS)
            .popover(item: $store.activitySide, attachmentAnchor: .point(UnitPoint(x: 0.5, y: 0.56))) { side in
                ActivityList(store: store, theme: theme, side: side)
            }
            #else
            .sheet(item: $store.activitySide) { side in
                ActivityList(store: store, theme: theme, side: side)
            }
            #endif
    }
}

private struct ActivityList: View {
    @ObservedObject var store: PadStore
    let theme: DailyTheme
    let side: ActivityPreference.Side
    @Environment(\.dismiss) private var dismiss

    private var ink: Color {
        if theme == .tungShing, let page = store.top.page {
            return page.holiday == nil ? PrintFace.dateInk(for: page) : PrintFace.green
        }
        return theme.original?.ink ?? Color(red: 0.16, green: 0.11, blue: 0.09)
    }

    private var dateInk: Color {
        guard let page = store.top.page else { return ink }
        if theme == .tungShing { return PrintFace.dateInk(for: page) }
        if let original = theme.original { return original.accent(for: DayInfo(page: page)) }
        return Ink.vermilion
    }

    private var design: Font.Design {
        switch theme {
        case .tungShing, .editorialDay: .default
        default: .serif
        }
    }

    @ViewBuilder private func dateNumber(_ day: Int) -> some View {
        switch theme {
        case .tungShing: TungShingNumeral(day: day, size: 49)
        case .koyomi: Text(verbatim: kanjiNumber(day)).font(Theme.mincho(32))
        default: Text(verbatim: String(day)).font(.system(size: 42, weight: .black, design: design))
        }
    }

    @ViewBuilder private var rule: some View {
        switch theme {
        case .tungShing, .tongsheng, .huangli:
            VStack(spacing: 2) {
                Rectangle().frame(height: 0.75)
                Rectangle().frame(height: 1.5)
            }
        default:
            Rectangle().frame(height: 1)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                if let page = store.top.page {
                    let info = DayInfo(page: page)
                    dateNumber(info.day).foregroundStyle(dateInk)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: weekdayNamesEN[info.weekday])
                            .foregroundColor(theme == .twinPillars ? ResearchFace.vermilion : nil)
                        Text(verbatim: monthNamesEN[info.month] + " " + String(info.year))
                    }
                    .font(.system(.caption, design: design, weight: .bold))
                    .textCase(.uppercase)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(info.date, format: .dateTime.weekday().month().day().year()))
                } else {
                    Text(verbatim: store.top.label)
                }
                Spacer(minLength: 4)
                Button("Done") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.system(.subheadline, design: design, weight: .semibold))
                    .padding(.horizontal, 6)
                    .keyboardShortcut(.cancelAction)
            }.padding(.horizontal, 16).padding(.vertical, 12)

            rule.foregroundStyle(dateInk)
            theme.activityHeading(side.title, onDarkPaper: true)
                .font(.system(.title2, design: design, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).padding(.vertical, 7)
                .foregroundStyle(theme.widgetPaper)
                .background(ink)
                .accessibilityAddTraits(.isHeader)

            if let page = store.top.page {
                let reading = side == .recommended ? page.recommended : page.avoided
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(reading.allLines.enumerated()), id: \.offset) { index, line in
                            if index > 0 { Rectangle().fill(ink.opacity(0.23)).frame(height: 0.5) }
                            Text(verbatim: line)
                                .font(.system(.body, design: design, weight: theme == .tungShing ? .semibold : .regular))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 9)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16)
                }
            } else if store.top.loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Almanac unavailable").padding()
            }
        }
        .foregroundStyle(ink)
        .tint(ink)
        .background {
            theme.widgetPaper
            PaperGrain(seed: Int(store.top.page?.date.day ?? 0), strength: theme.original?.grainStrength ?? 1)
        }
        .presentationBackground(theme.widgetPaper)
        #if os(macOS)
        .frame(width: 320, height: 360)
        #else
        .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        #endif
    }
}

extension View {
    func activityLists(store: PadStore, theme: DailyTheme) -> some View {
        modifier(ActivityListPresenter(store: store, theme: theme))
    }

    func activityListActions(store: PadStore, enabled: Bool = true) -> some View {
        accessibilityActions {
            if enabled, let page = store.top.page {
                if page.recommended.remaining > 0 {
                    Button("Show all Do activities") { store.activitySide = .recommended }
                }
                if page.avoided.remaining > 0 {
                    Button("Show all Avoid activities") { store.activitySide = .avoided }
                }
            }
        }
    }
}
