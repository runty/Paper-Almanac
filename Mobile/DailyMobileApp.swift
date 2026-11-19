import SwiftUI
import UIKit
import WidgetKit

@main
struct DailyMobileApp: App {
    var body: some Scene {
        WindowGroup { AlmanacWindow() }
            .commands { DayCommands() }
    }
}

private struct DayNavigation {
    let pad: PadStore
    let pickDate: () -> Void
}

private extension FocusedValues {
    @Entry var dayNavigation: DayNavigation?
}

private struct DayCommands: Commands {
    @FocusedValue(\.dayNavigation) private var navigation

    var body: some Commands {
        CommandMenu("Date") {
            Button("Previous Day") { navigation?.pad.step(-1) }.keyboardShortcut(.leftArrow, modifiers: [])
            Button("Next Day") { navigation?.pad.step(1) }.keyboardShortcut(.rightArrow, modifiers: [])
            Button("Today") { navigation?.pad.today() }.keyboardShortcut("t", modifiers: .command)
            Button("Go to Date…") { navigation?.pickDate() }.keyboardShortcut("l", modifiers: .command)
        }
    }
}

private struct AlmanacWindow: View {
    @StateObject private var store = PadStore()
    @AppStorage(DailyTheme.key, store: DailyTheme.defaults) private var theme: DailyTheme = .tungShing
    @AppStorage(PadStore.advanceKey) private var liveAdvance: String?
    @AppStorage(DailyTheme.calendarLayoutKey, store: DailyTheme.defaults) private var calendarLayout = false
    @Environment(\.scenePhase) private var phase
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var pickingDate = false
    @State private var showingAbout = false
    @State private var picked = Date.now

    private var themeSelection: Binding<DailyTheme> {
        Binding(get: { theme }, set: { selection in
            guard selection != theme else { return }
            calendarLayout = selection.opensWithCalendar
            theme = selection
        })
    }

    private var padSize: CGSize {
        switch theme {
        case .fuji: CGSize(width: 386, height: 510)
        case .celestialAlmanac: CGSize(width: 310, height: 418 + CelestialBinding.headroom)
        default: CGSize(width: 310, height: 418)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if theme.original != nil {
                    button(calendarLayout ? "Show Do and Don’t" : "Show Month Calendar",
                           calendarLayout ? "list.bullet" : "calendar") { calendarLayout.toggle() }
                        .accessibilityIdentifier("himekuri-layout")
                }
                Menu {
                    Button("Go to Date…", systemImage: "calendar") { openPicker() }
                        .accessibilityIdentifier("go-to-date")
                    Divider()
                    Picker("Theme", selection: themeSelection) {
                        ForEach(DailyTheme.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.inline)
                    Divider()
                    Button("About", systemImage: "info.circle") { showingAbout = true }
                } label: { Image(systemName: "paintpalette").frame(width: 44, height: 44) }
                    .menuOrder(.fixed)
                    .accessibilityLabel("Theme").accessibilityValue(theme.title)
            }.padding(.horizontal, 22)
            GeometryReader { space in
                if textSize.isAccessibilitySize {
                    AccessibleDay(sheet: store.top, theme: theme, calendarLayout: calendarLayout, today: store.today)
                        .accessibilityAction(named: "Previous day") { store.step(-1) }
                        .accessibilityAction(named: "Next day") { store.step(1) }
                } else {
                    let width = min(space.size.width - 32, (space.size.height - 18) * padSize.width / padSize.height, 640)
                    if width >= 265 {
                        paper(width: width).frame(width: space.size.width, height: space.size.height)
                    } else {
                        ScrollView { paper(width: min(space.size.width - 32, 390)).padding(.vertical, 12)
                                .frame(maxWidth: .infinity) }
                    }
                }
            }
        }
        .foregroundStyle(Color(red: 0.16, green: 0.19, blue: 0.16))
        .tint(Color(red: 0.08, green: 0.30, blue: 0.23))
        .background {
            if theme == .celestialAlmanac {
                LinearGradient(colors: [Color(red: 0.76, green: 0.74, blue: 0.76),
                                        Color(red: 0.706, green: 0.687, blue: 0.714),
                                        Color(red: 0.65, green: 0.63, blue: 0.66)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            } else {
                Color(red: 0.82, green: 0.81, blue: 0.78).ignoresSafeArea()
            }
        }
        .activityLists(store: store, theme: theme)
        .preferredColorScheme(.light)
        .focusedSceneValue(\.dayNavigation, pickingDate ? nil : DayNavigation(pad: store, pickDate: openPicker))
        .onChange(of: calendarLayout) { WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget") }
        .onChange(of: theme) { WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget") }
        .onChange(of: liveAdvance) { store.refreshToday() }
        .onChange(of: phase) {
            if phase == .active {
                store.refreshToday()
                WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            store.refreshToday()
            WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget")
        }
        .onOpenURL { url in
            if store.openDay(url) { pickingDate = false }
        }
        .sheet(isPresented: $showingAbout) {
            NavigationStack {
                AboutAlmanac()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Done") { showingAbout = false } }
                    }
            }
        }
        .sheet(isPresented: $pickingDate) {
            NavigationStack {
                DatePicker("Date", selection: $picked, in: civilDate("1901-01-01")!...civilDate("2100-12-31")!, displayedComponents: .date)
                    .datePickerStyle(.graphical).padding().accessibilityIdentifier("date-picker")
                    .navigationTitle("Go to Date").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { pickingDate = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Show") { store.browse(CivilDay.label(picked)); pickingDate = false }
                        }
                    }
            }.presentationDetents([.medium, .large]).environment(\.calendar, CivilDay.calendar())
        }
    }

    private func paper(width: CGFloat) -> some View {
        let scale = width / padSize.width
        return MobilePad(store: store, theme: theme, calendarLayout: calendarLayout,
                         pageScale: scale)
            .padding(.top, theme == .fuji ? 66 : 0)
            .padding(.bottom, theme == .fuji ? 26 : 0)
            .padding(.top, theme == .celestialAlmanac ? CelestialBinding.headroom : 0)
            .frame(width: padSize.width, height: padSize.height)
            .background { if theme == .fuji { FujiCardboard() } }
            .scaleEffect(scale).frame(width: width, height: padSize.height * scale)
    }

    private func button(_ name: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).frame(width: 44, height: 44) }.accessibilityLabel(name)
    }
    private func civilDate(_ label: String) -> Date? {
        let fields = label.split(separator: "-").compactMap { Int($0) }
        guard fields.count == 3 else { return nil }
        return CivilDay.calendar().date(from: DateComponents(year: fields[0], month: fields[1], day: fields[2], hour: 12))
    }
    private func openPicker() { picked = civilDate(store.top.label) ?? .now; pickingDate = true }
}

private struct AccessibleDay: View {
    let sheet: Sheet
    let theme: DailyTheme
    let calendarLayout: Bool
    let today: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: today) { Text(verbatim: sheet.label).font(.title.bold()) }
                    .buttonStyle(.plain).accessibilityHint("Return to today")
                if let day = sheet.page, theme == .fuji {
                    let reading = FujiReading(day)
                    Text(verbatim: reading.weekday)
                    if let holiday = reading.holidayLine { Text(verbatim: holiday) }
                    if let rokuyo = reading.rokuyo { Text(verbatim: "Rokuyō · " + rokuyo + " " + (reading.romanization ?? "")) }
                    if let moon = reading.moonDescription { Text(verbatim: moon) }
                } else if let day = sheet.page {
                    Text(verbatim: day.report.weekdayLabel + " · " + day.report.lunarMonthLabel + day.report.lunarDayLabel)
                    let term = day.report.termOnDate ?? day.report.nextTerm
                    Text(verbatim: (day.report.termOnDate == nil ? "Next solar term · " : "Solar term · ") + termName(term) + " · " + term.date.label)
                    if let holiday = day.holiday { Text(verbatim: holiday.chinese + " · " + holiday.english) }
                    if theme == .celestialAlmanac {
                        let value = CelestialReading(day)
                        Text(verbatim: value.summary)
                        Link(value.launchCredit ?? "Historical source", destination: value.history.sourceURL)
                    } else if calendarLayout, let original = theme.original {
                        let info = DayInfo(page: day)
                        Text(info.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                        if let proverb = info.calendarProverb(for: original) { Text(verbatim: proverb) }
                        ForEach(Array(info.grid.enumerated()), id: \.offset) { _, week in
                            Text(verbatim: week.compactMap { $0 }.map(String.init).joined(separator: " · "))
                        }
                    } else {
                        section("宜 · Do", .recommended, day.recommended)
                        section("忌 · Avoid", .avoided, day.avoided)
                        if theme == .tungShing, let proverb = ChineseProverb.on(day.date) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Chinese proverb").font(.headline).accessibilityAddTraits(.isHeader)
                                Text(verbatim: proverb.english)
                            }
                        }
                    }
                } else { Text(sheet.loading ? "Opening the almanac…" : "Almanac unavailable") }
            }.padding().frame(maxWidth: .infinity, alignment: .leading)
        }.background(.background).padding(.horizontal, 12)
    }
    private func section(_ title: String, _ side: ActivityPreference.Side, _ reading: Reading) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            theme.activityHeading(title).font(.headline).accessibilityAddTraits(.isHeader)
            ForEach(reading.lines, id: \.self) { Text(verbatim: $0) }
            if reading.remaining > 0 { Text("+\(reading.remaining) more").font(.footnote) }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .activityLink(day: sheet.label, side: side)
    }
}
