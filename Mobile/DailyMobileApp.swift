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
    @ObservedObject private var location = MoonLocation.shared
    @StateObject private var store = PadStore()
    @AppStorage(DailyTheme.key, store: DailyTheme.defaults) private var theme: DailyTheme = .tungShing
    @AppStorage(PadStore.advanceKey) private var liveAdvance: String?
    @AppStorage(PadStore.heldDayKey) private var heldDay: String?
    @AppStorage(DailyTheme.calendarLayoutKey, store: DailyTheme.defaults) private var calendarLayout = false
    @Environment(\.scenePhase) private var phase
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.layoutDirection) private var direction
    @State private var hingeStatus: DeviceHinge.Status?
    @State private var coverPaletteCenter: CGPoint?
    @AppStorage("duo.coverCalendarViewport") private var coverViewport = ""
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
        case .kinun: CGSize(width: Kinun.boardWidth, height: 418 + Kinun.headerHeight)
        case .tsukigoyomi: CGSize(width: 332, height: 474)
        case .fuji: CGSize(width: 386, height: 510)
        case .celestialAlmanac: CGSize(width: 310, height: 418 + CelestialBinding.headroom)
        default: CGSize(width: 310, height: 418)
        }
    }

    var body: some View {
        GeometryReader { space in
            if space.size.width > space.size.height, hingeStatus == .partiallyOpen || hingeStatus == .fullyOpen {
                openDuoLayout(in: space)
            } else {
                VStack(spacing: 0) {
                    toolbar
                    calendarPane
                        .onGeometryChange(for: CGRect?.self) { pane in
                            guard hingeStatus == .closed, space.size.width < space.size.height else { return nil }
                            let window = space.frame(in: .global)
                            let frame = pane.frame(in: .global)
                            // Record the calendar area relative to the cover’s physical top and right edges.
                            return CGRect(x: window.maxX - frame.maxX + rightInset(in: space),
                                          y: frame.minY - window.minY + space.safeAreaInsets.top,
                                          width: frame.width, height: frame.height)
                        } action: { viewport in
                            if let viewport, !viewport.isEmpty { coverViewport = NSCoder.string(for: viewport) }
                        }
                }
            }
        }
        .overlay {
            if hingeStatus == .closed {
                GeometryReader { display in
                    if let center = coverPalettePosition(in: display) {
                        paletteMenu
                            .environment(\.layoutDirection, direction)
                            .position(center)
                    }
                }
                .onGeometryChange(for: CGPoint?.self) { display in
                    coverPalettePosition(in: display)
                } action: { coverPaletteCenter = $0 }
                .environment(\.layoutDirection, .leftToRight)
                .ignoresSafeArea(.container)
                .onDisappear { coverPaletteCenter = nil }
            }
        }
        .onHingeChange { _, context in hingeStatus = context.hinge?.status }
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
        .onAppear { if theme == .moon { location.refresh() } }
        .onReceive(location.$site) { store.updateSkySite($0) }
        .alert("Sky Notes", isPresented: Binding(get: { location.message != nil }, set: { if !$0 { location.message = nil } })) {
            Button("OK") { location.message = nil }
        } message: { Text(location.message ?? "") }
        .onChange(of: theme) {
            if theme == .moon { location.refresh() }
            WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget")
        }
        .onChange(of: liveAdvance) { store.refreshToday() }
        .onChange(of: heldDay) { store.refreshToday() }
        .onChange(of: phase) {
            if phase == .active {
                if theme == .moon { location.refresh() }
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
                        ToolbarItemGroup(placement: .confirmationAction) {
                            Button("Today") { store.today(); pickingDate = false }
                            Button("Show") { store.browse(CivilDay.label(picked)); pickingDate = false }
                        }
                    }
            }.presentationDetents([.medium, .large]).environment(\.calendar, CivilDay.calendar())
        }
    }

    private func rightInset(in space: GeometryProxy) -> CGFloat {
        direction == .leftToRight ? space.safeAreaInsets.trailing : space.safeAreaInsets.leading
    }

    private func openDuoLayout(in space: GeometryProxy) -> some View {
        let insets = space.safeAreaInsets
        let fullWidth = space.size.width + insets.leading + insets.trailing
        let fullHeight = space.size.height + insets.top + insets.bottom
        let halfWidth = fullWidth / 2
        let right = rightInset(in: space)
        let left = insets.leading + insets.trailing - right
        let cover = NSCoder.cgRect(for: coverViewport)
        let hasCover = !cover.isEmpty
        let width = hasCover ? min(cover.width, halfWidth) : halfWidth - right
        let height = hasCover ? min(cover.height, fullHeight) : space.size.height
        let centerFromRight = hasCover ? min(cover.minX + width / 2, halfWidth - width / 2) : halfWidth / 2
        let centerFromTop = hasCover ? cover.minY + height / 2 : fullHeight / 2

        return ZStack {
            sidebar
                .environment(\.layoutDirection, direction)
                .frame(width: halfWidth - left)
                .position(x: (halfWidth - left) / 2, y: space.size.height / 2)
            calendarPane
                .environment(\.layoutDirection, direction)
                .frame(width: width, height: height)
                .position(x: space.size.width + right - centerFromRight, y: centerFromTop - insets.top)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func coverPalettePosition(in display: GeometryProxy) -> CGPoint? {
        let regions = display.reservedRegions(kind: .occlusion, layoutDirectionBehavior: .fixed).map(\.frame)
        // The cover reports the indicator strip and the camera cutout within it.
        guard let strip = regions.first(where: {
            $0.minX > display.size.width / 2 && $0.maxX >= display.size.width - 1 &&
            $0.minY <= 1 && $0.maxY + 44 <= display.size.height
        }) else { return nil }
        let cutout = regions.first { $0 != strip && strip.contains($0) }
        return CGPoint(x: cutout?.midX ?? strip.midX, y: strip.maxY + 22)
    }

    private var toolbar: some View {
        HStack {
            Spacer()
            if theme.original != nil {
                button(layoutTitle, layoutIcon) { calendarLayout.toggle() }
                    .accessibilityIdentifier("himekuri-layout")
            }
            if hingeStatus != .closed || coverPaletteCenter == nil {
                paletteMenu
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 22)
    }

    private var paletteMenu: some View {
        Menu {
            menuActions
            aboutButton
            Divider()
            Picker("Theme", selection: themeSelection) {
                ForEach(DailyTheme.allCases) { Text($0.title).tag($0) }
            }.pickerStyle(.inline)
        } label: { Image(systemName: "paintbrush.pointed.fill").frame(width: 44, height: 44) }
            .menuOrder(.fixed)
            .accessibilityLabel("Theme").accessibilityValue(theme.title)
    }

    @ViewBuilder private var menuActions: some View {
        Button("Go to Date…", systemImage: "calendar") { openPicker() }
            .accessibilityIdentifier("go-to-date")
        Toggle(isOn: Binding(get: { store.automaticallyUpdatesDate }, set: store.setAutomaticallyUpdatesDate)) {
            Label("Auto Change Date", systemImage: "calendar.badge.clock")
        }
        if theme == .moon {
            Toggle(isOn: Binding(get: { location.enabled }, set: location.setEnabled)) {
                Label("Use Current Location", systemImage: "location")
            }
        }
    }

    private var aboutButton: some View {
        Button("About", systemImage: "info.circle") { showingAbout = true }
    }

    private var layoutTitle: String { calendarLayout ? "Show Do and Don’t" : "Show Month Calendar" }
    private var layoutIcon: String { calendarLayout ? "list.bullet" : "calendar" }

    @ScaledMetric(relativeTo: .subheadline) private var sidebarWidth: CGFloat = 300

    private var sidebarFont: Font {
        switch theme {
        case .fuji, .moon: .custom("HelveticaNeue", size: 15, relativeTo: .subheadline)
        case .lichViet, .illyeok: .custom("Georgia", size: 15, relativeTo: .subheadline)
        case .koyomi, .showa, .tongsheng, .huangli, .tsukigoyomi, .nihon, .kinun,
             .editorialDay: .system(.subheadline, design: .serif)
        case .celestialAlmanac: .system(.subheadline, design: .rounded)
        case .tungShing, .twinPillars: .subheadline
        }
    }

    private var sidebar: some View {
        List {
            Section {
                menuActions
                    .toggleStyle(SidebarCheckmarkStyle())
                    .listRowSeparator(.hidden)
                if theme.original != nil {
                    Button(layoutTitle, systemImage: layoutIcon) { calendarLayout.toggle() }
                        .accessibilityIdentifier("himekuri-layout")
                        .listRowSeparator(.hidden)
                }
                aboutButton.listRowSeparator(.hidden)
            }
            .listRowInsets(.vertical, 4)
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden, edges: .top)
            .listSectionSeparator(.visible, edges: .bottom)
            Section {
                ForEach(DailyTheme.allCases) { item in
                    Button {
                        themeSelection.wrappedValue = item
                    } label: {
                        HStack {
                            Text(item.title)
                            Spacer()
                            if item == theme {
                                Image(systemName: "checkmark").imageScale(.small).accessibilityHidden(true)
                            }
                        }.contentShape(Rectangle())
                    }
                    .fontWeight(item == theme ? .semibold : .regular)
                    .accessibilityAddTraits(item == theme ? .isSelected : [])
                }
                .listRowSeparator(.hidden)
            } header: {
                Text("Theme")
                    .font(.caption.weight(.semibold)).textCase(.uppercase).tracking(1.2)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowInsets(.vertical, 4)
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, textSize.isAccessibilitySize ? 44 : 36)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .font(sidebarFont)
        .foregroundStyle(Color(red: 0.29, green: 0.29, blue: 0.28))
        .tint(Color(red: 0.38, green: 0.39, blue: 0.37))
        .contentMargins(.vertical, 8, for: .scrollContent)
        .controlSize(.small)
        .frame(maxWidth: sidebarWidth)
        .padding(.horizontal, textSize.isAccessibilitySize ? 16 : 32)
        .padding(.vertical, 64)
        .accessibilityIdentifier("duo-menu")
    }

    private var calendarPane: some View {
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

    private func paper(width: CGFloat) -> some View {
        let scale = width / padSize.width
        return MobilePad(store: store, theme: theme, calendarLayout: calendarLayout,
                         pageScale: scale)
            .padding(.top, theme == .fuji ? 66 : 0)
            .padding(.bottom, theme == .fuji ? 26 : 0)
            .padding(.top, theme == .celestialAlmanac ? CelestialBinding.headroom : 0)
            .padding(.top, theme == .kinun ? Kinun.headerHeight : 0)
            .padding(.top, theme == .tsukigoyomi ? 38 : 0)
            .frame(width: padSize.width, height: padSize.height)
            .background {
                if theme == .fuji { FujiCardboard() }
                if theme == .kinun { KinunBoard().allowsHitTesting(false) }
                if theme == .tsukigoyomi { TsukigoyomiBoard().allowsHitTesting(false) }
            }
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

private struct SidebarCheckmarkStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .font(.subheadline.weight(.regular))
                    .opacity(configuration.isOn ? 0.9 : 0.75)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
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
                if let day = sheet.page, theme == .tsukigoyomi {
                    let value = TsukigoyomiReading(day)
                    if let rokuyo = value.almanac.traditions.rokuyo {
                        Text(verbatim: value.info.weekdayEN.uppercased() + "  ·  六曜 " + rokuyo)
                    }
                    Text(verbatim: [value.phase, value.almanac.oldDate].joined(separator: "  ·  "))
                    Text(verbatim: "月齢  " + (value.almanac.age ?? "—") + "    潮名  " + value.almanac.tide)
                    if let season = value.season {
                        Text(verbatim: season.term + "  ·  " + season.termEnglish)
                        Text(verbatim: season.microseason).font(.headline)
                        Text(verbatim: season.microseasonEnglish)
                    }
                } else if let day = sheet.page, theme == .lichViet {
                    let reading = LichVietReading(day)
                    Text(verbatim: reading.weekday + "  ·  " + reading.lunarLine)
                    Text(verbatim: "Năm " + reading.yearName + "  ·  Ngày " + reading.dayName)
                    if let festival = reading.festival { Text(verbatim: festival.name + "  ·  " + festival.english).font(.headline) }
                } else if let day = sheet.page, theme == .illyeok {
                    let value = IllyeokReading(day)
                    Text(verbatim: value.weekday + "  ·  " + value.dateLine)
                    Text(verbatim: value.proverb.korean).font(.headline)
                    Text(verbatim: value.proverb.english)
                } else if let day = sheet.page, theme == .nihon || theme == .kinun {
                    let value = NihonReading(day)
                    Text(verbatim: [value.weekday, value.holiday, value.oldDate].compactMap { $0 }.joined(separator: "  ·  "))
                    Text(verbatim: "六曜  " + value.rokuyo + "  " + (value.traditions.rokuyoRomanized ?? ""))
                    if theme == .kinun && Kinun.isGrainDay(day) { Text("一粒万倍日 · One grain, ten thousandfold").font(.headline) }
                    Text(verbatim: "二十八宿  " + value.mansion + "宿")
                    Text(verbatim: "月齢  " + (value.age ?? "—") + "    潮名  " + value.tide)
                    Text(verbatim: value.info.proverb.jp).font(.headline)
                    Text(verbatim: value.info.proverb.en)
                } else if let day = sheet.page, theme == .moon {
                    let reading = MoonReading(day, site: sheet.skySite)
                    Text(verbatim: [reading.phase, reading.illumination].compactMap { $0 }.joined(separator: " · "))
                    Text(verbatim: reading.caption).font(.headline)
                    Text(verbatim: reading.note)
                } else if let day = sheet.page, theme == .fuji {
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
            .activityLink(side: side)
    }
}
