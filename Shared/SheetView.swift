import SwiftUI

extension EnvironmentValues {
    @Entry var isWidgetSheet = false
}

struct SheetView: View {
    let sheet: Sheet
    let theme: DailyTheme
    var calendarLayout = false
    var widgetSize: CGSize?
    var body: some View {
        ZStack {
            (theme == .kinun ? Kinun.paper : theme.original?.paper ?? Color(red: 1, green: 0.994, blue: 0.98))
            if let page = sheet.page {
                if theme == .tungShing {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 25)
                        PrintFace(day: page).scaleEffect(0.75).frame(width: 300, height: 375)
                    }
                } else if theme == .tsukigoyomi {
                    TsukigoyomiFace(reading: TsukigoyomiReading(page), widget: widgetSize != nil)
                } else if theme == .lichViet {
                    LichVietFace(reading: LichVietReading(page), widget: widgetSize != nil)
                } else if theme == .illyeok {
                    IllyeokFace(reading: IllyeokReading(page), widget: widgetSize != nil)
                } else if theme == .nihon || theme == .kinun {
                    NihonFace(reading: NihonReading(page), widget: widgetSize != nil, goldFortune: theme == .kinun)
                } else if theme == .moon {
                    MoonFace(reading: MoonReading(page, site: sheet.skySite), widget: widgetSize != nil)
                } else if theme == .fuji {
                    FujiFace(reading: FujiReading(page))
                } else if let t = theme.original {
                    PaperGrain(seed: Int(page.date.month) * 32 + Int(page.date.day), strength: t.grainStrength)
                    originalFace(DayInfo(page: page, calendarLayout: calendarLayout), t).foregroundStyle(t.ink)
                } else if theme == .celestialAlmanac {
                    CelestialFace(reading: CelestialReading(page))
                } else {
                    ResearchFace(page: page, theme: theme)
                }
            } else {
                VStack(spacing: 15) {
                    Text(verbatim: sheet.label).font(.title.bold()).dayNumberTarget()
                    Text(sheet.loading ? "Opening the almanac…" : "Almanac unavailable")
                }.foregroundStyle(.black)
            }
        }.frame(width: widgetSize?.width ?? 300, height: widgetSize?.height ?? 400)
            .clipShape(RoundedRectangle(cornerRadius: widgetSize == nil ? 2 : 0))
            .environment(\.isWidgetSheet, widgetSize != nil)
            .environment(\.colorScheme, .light)
            .accessibilityElement(children: .ignore).accessibilityLabel(sheet.description(for: theme, calendarLayout: calendarLayout))
    }
    @ViewBuilder private func originalFace(_ info: DayInfo, _ t: PageTheme) -> some View {
        switch t {
        case .showa: ShowaLayout(info: info, t: t)
        case .koyomi: KoyomiLayout(info: info, t: t)
        case .huangli: HuangliLayout(info: info, t: t)
        case .tongsheng: TongshengLayout(info: info, t: t)
        }
    }
}

struct ResearchFace: View {
    let page: PrintedDay
    let theme: DailyTheme
    private var info: DayInfo { DayInfo(page: page) }
    private let ink = Color(red: 0.16, green: 0.11, blue: 0.09)
    static let vermilion = Color(red: 0.65, green: 0.11, blue: 0.10)
    var body: some View {
        VStack(spacing: 0) {
            switch theme {
            case .twinPillars:
                HStack(spacing: 8) {
                    VerticalText(info.yearPillar, font: Theme.mincho(18), color: ink, spacing: 3)
                        .frame(width: 24)
                    VStack(spacing: 2) {
                        Text(verbatim: monthNamesEN[info.month] + " " + String(info.year)).font(.headline)
                        dayNumber(.serif, 120).lineLimit(1).minimumScaleFactor(0.65)
                        Text(verbatim: weekdayNamesEN[info.weekday]).font(.headline).foregroundStyle(Self.vermilion)
                        Text(verbatim: info.lunarCaption).font(.title3)
                    }.frame(maxWidth: .infinity)
                    VerticalText(info.report.dayPillar.label + "日", font: Theme.mincho(18), color: ink, spacing: 3)
                        .frame(width: 24)
                }.frame(maxHeight: .infinity)
                Rectangle().fill(ink.opacity(0.45)).frame(height: 0.75)
                ActivityPanel(page: page, design: .serif, theme: theme).padding(.vertical, 12)
            default:
                VStack(alignment: .leading, spacing: 3) {
                    Text(monthNamesEN[info.month]).font(.headline).tracking(3)
                    dayNumber(.serif, 105)
                    Text(weekdayNamesEN[info.weekday] + "  ·  " + info.lunarCaption).font(.subheadline)
                    Spacer()
                    editorialRow("宜", .recommended, page.recommended)
                    editorialRow("忌", .avoided, page.avoided)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(.horizontal, 18).padding(.top, 34).padding(.bottom, 16).foregroundStyle(ink)
    }
    private func dayNumber(_ design: Font.Design, _ size: CGFloat) -> some View {
        Text(verbatim: String(info.day)).font(.system(size: size, weight: .black, design: design)).dayNumberTarget()
    }
    private func editorialRow(_ symbol: String, _ side: ActivityPreference.Side, _ reading: Reading) -> some View {
        VStack { Divider(); HStack(alignment: .top) { Text(symbol).font(.title3.bold()).foregroundStyle(Self.vermilion)
            Text(reading.lines.joined(separator: " · ")).font(.system(size: 11)).frame(maxWidth: .infinity, alignment: .leading)
        }}.padding(.vertical, 4)
            .activityLink(day: page.date.label, side: side)
    }
}
