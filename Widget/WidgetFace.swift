import SwiftUI
import WidgetKit

struct WidgetFace: View {
    let entry: DailyEntry
    let family: WidgetFamily
    #if os(iOS)
    @Environment(\.showsWidgetContainerBackground) private var showsBackground
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.widgetContentMargins) private var contentMargins
    #endif

    var body: some View {
        Group {
            #if os(iOS)
            if family == .systemSmall && !showsBackground && renderingMode == .fullColor {
                DashboardAlmanac(entry: entry)
                    .padding(contentMargins)
            } else {
                paperFace
            }
            #else
            paperFace
            #endif
        }
        .containerBackground(for: .widget) { entry.theme.widgetPaper }
        .environment(\.widgetActivityLinks, true)
        .widgetURL(URL(string: "tungshingdaily://day/" + entry.sheet.label))
        .accessibilityElement(children: .combine)
    }

    private var paperFace: some View {
        GeometryReader { box in
            if entry.theme == .tsukigoyomi, let page = entry.sheet.page {
                TsukigoyomiFace(reading: TsukigoyomiReading(page), widget: true)
            } else if entry.theme == .illyeok, let page = entry.sheet.page {
                IllyeokFace(reading: IllyeokReading(page), widget: true)
            } else if entry.theme == .nihon, let page = entry.sheet.page {
                NihonFace(reading: NihonReading(page), widget: true)
            } else if entry.theme == .moon, let page = entry.sheet.page {
                MoonFace(reading: MoonReading(page, site: entry.sheet.skySite), widget: true)
            } else if entry.theme == .fuji, let page = entry.sheet.page {
                FujiFace(reading: FujiReading(page), widget: true)
            } else if family == .systemLarge || family == .systemExtraLargePortrait {
                fittedPaper(in: box.size)
            } else if entry.theme == .celestialAlmanac, let page = entry.sheet.page {
                if family == .systemExtraLarge {
                    HStack(spacing: 20) {
                        fittedPaper(in: CGSize(width: box.size.width * 0.44, height: box.size.height))
                        celestialObservation(CelestialReading(page))
                    }.padding(.horizontal, 12)
                } else {
                    let reading = CelestialReading(page)
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text(verbatim: monthNamesEN[reading.info.month].uppercased()).font(.caption.bold()).tracking(1)
                            CelestialNumeral(day: reading.info.day, height: min(68, box.size.height * 0.43))
                                .foregroundStyle(CelestialFace.ink(weekday: reading.info.weekday))
                            Text(verbatim: reading.tradition.rokuyo ?? "—").font(.caption.bold())
                            Text(verbatim: reading.sign + " · " + reading.moon).font(.caption2)
                        }.frame(maxWidth: .infinity)
                        if family == .systemMedium {
                            celestialNotes(reading).frame(maxWidth: .infinity)
                        }
                    }.padding(10).frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(CelestialFace.black)
                }
            } else if entry.calendarLayout, let original = entry.theme.original, let page = entry.sheet.page {
                let info = DayInfo(page: page)
                if family == .systemSmall {
                    calendarCaption(info: info, theme: original)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if family == .systemMedium || family == .systemExtraLarge {
                    HStack(spacing: 10) {
                        fittedPaper(in: CGSize(width: box.size.width * 0.45, height: box.size.height - 6))
                        calendarCaption(info: info, theme: original)
                            .frame(maxWidth: .infinity)
                    }.frame(maxHeight: .infinity)
                } else {
                    fittedPaper(in: box.size)
                }
            } else if family == .systemExtraLarge, let page = entry.sheet.page {
                let ink = widgetPalette(theme: entry.theme, page: page)
                HStack(spacing: 20) {
                    fittedPaper(in: CGSize(width: box.size.width * 0.43, height: box.size.height - 12))
                    VStack(alignment: .leading, spacing: 10) {
                        Text(verbatim: weekdayNamesEN[page.date.weekdaySunday0 + 1] + " · " + page.report.weekdayLabel)
                            .font(.headline).foregroundStyle(entry.theme == .deskLedger ? ResearchFace.vermilion : ink)
                        Rectangle().fill(ink).frame(height: 1)
                        expandedList("宜  DO", .recommended, page.recommended)
                        expandedList("忌  AVOID", .avoided, page.avoided)
                    }
                    .foregroundStyle(entry.theme == .tungShing && page.holiday != nil
                        ? Color(red: 0.025, green: 0.32, blue: 0.22) : ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if family == .systemExtraLarge {
                fittedPaper(in: box.size)
            } else if family == .systemMedium, let page = entry.sheet.page {
                let palette = widgetPalette(theme: entry.theme, page: page)
                HStack(spacing: 10) {
                    fittedPaper(in: CGSize(width: min(box.size.width * 0.46, box.size.height * 0.8), height: box.size.height - 10))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: weekdayNamesEN[page.date.weekdaySunday0 + 1])
                            .font(.caption.weight(.black)).tracking(1)
                            .foregroundColor(entry.theme == .deskLedger ? ResearchFace.vermilion : nil)
                        Divider()
                        ViewThatFits(in: .vertical) {
                            mediumReadings(page, count: 2)
                            mediumReadings(page, count: 1)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(page.holiday != nil && entry.theme == .tungShing ? Color(red: 0.025, green: 0.32, blue: 0.22) : palette)
                }.padding(.horizontal, 9).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if entry.theme == .tungShing, let page = entry.sheet.page {
                CompactTungShing(page: page, dateInk: PrintFace.dateInk(for: page),
                                 ink: page.holiday == nil ? PrintFace.dateInk(for: page) : PrintFace.green,
                                 paper: entry.theme.widgetPaper)
                    .padding(8)
            } else if let page = entry.sheet.page {
                let palette = widgetPalette(theme: entry.theme, page: page)
                ViewThatFits(in: .vertical) {
                    smallPage(page, ink: palette, compact: false)
                    smallPage(page, ink: palette, compact: true)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack { Text(verbatim: entry.sheet.label); Text(entry.sheet.loading ? "Daily Almanac" : "Almanac unavailable") }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.environment(\.colorScheme, .light)
    }
    private func celestialObservation(_ reading: CelestialReading) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Lunar observation").font(.system(.headline, design: .monospaced))
            HStack(spacing: 12) {
                CelestialDial(kind: .moon, reading: reading).frame(width: 58, height: 58)
                VStack(alignment: .leading) {
                    Text(verbatim: reading.moon).font(.title2.bold())
                    if let sky = reading.sky {
                        Text(sky.moonIsWaxing ? "Waxing" : "Waning")
                    }
                    if let age = reading.moonAge { Text(verbatim: age + " days since new moon").font(.caption) }
                }
            }
            Text(verbatim: "Tokyo daylight  " + reading.daylight)
            Divider()
            Text(verbatim: String(reading.history.year)).font(.headline.monospacedDigit())
            Text(verbatim: reading.history.text)
            if let credit = reading.launchCredit { Text(verbatim: credit).font(.caption2) }
        }.font(.subheadline).foregroundStyle(CelestialFace.black)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func celestialNotes(_ reading: CelestialReading) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                ForEach([CelestialDial.Kind.planets, .moon, .zodiac], id: \.self) { kind in
                    CelestialDial(kind: kind, reading: reading).frame(width: 32, height: 32)
                }
            }
            Text(verbatim: reading.tradition.dayAnimal + " · " + reading.sign).font(.caption.bold())
            Text(verbatim: String(reading.history.year) + "  " + reading.history.text)
                .font(.caption2).lineLimit(4)
        }.foregroundStyle(CelestialFace.black)
    }

    private func smallPage(_ page: PrintedDay, ink: Color, compact: Bool) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: monthNamesEN[Int(page.date.month)] + " " + String(page.date.year)).font(.caption.bold())
            Text(verbatim: String(page.date.day))
                .font(.system(size: compact ? 40 : 59, weight: .black, design: widgetDesign))
                .foregroundStyle(ink)
            let weekday = Text(verbatim: page.report.weekdayLabel).foregroundColor(entry.theme == .deskLedger ? ResearchFace.vermilion : nil)
            Text("\(weekday) · \(page.report.lunarDayLabel)").font(.caption.bold())
            if let line = page.recommended.lines.first { entry.theme.activityHeading("宜 " + line) }
            if let line = page.avoided.lines.first { entry.theme.activityHeading("忌 " + line) }
        }
        .font(.system(size: compact ? 10 : 11, design: widgetDesign))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(entry.theme == .tungShing && page.holiday != nil
                         ? Color(red: 0.025, green: 0.32, blue: 0.22) : ink)
        .widgetAccentable()
    }

    private func calendarCaption(info: DayInfo, theme: PageTheme) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: monthNamesEN[info.month] + " " + String(info.year)).font(.caption.bold())
            MonthGrid(info: info, t: theme,
                      customHeaders: [.huangli, .tongsheng].contains(theme) ? Array("日一二三四五六").map(String.init) : nil,
                      scale: family == .systemExtraLarge ? 1.85 : 1)
            if family == .systemExtraLarge, let proverb = info.calendarProverb(for: theme) {
                Text(verbatim: proverb).font(.callout)
            }
        }.foregroundStyle(theme.ink)
    }
    @ViewBuilder private func fittedPaper(in size: CGSize) -> some View {
        let isTallPortrait = family == .systemExtraLargePortrait
        if entry.theme == .tungShing, let page = entry.sheet.page, size.width > 0, size.height > 0 {
            // Keep the print type and seals proportional. Give wider widgets longer rules and columns.
            let scale = min(size.height / 500, size.width / 400)
            PrintFace(day: page, plateWidth: size.width / scale,
                      plateHeight: isTallPortrait ? size.height / scale : 500, showsPageBorder: false)
                .scaleEffect(scale)
                .frame(width: size.width, height: size.height)
                .accessibilityElement(children: .ignore).accessibilityLabel(entry.sheet.description(for: entry.theme, calendarLayout: entry.calendarLayout))
        } else if size.width > 0, size.height > 0 {
            // Omit the binding area but leave room for the widget's rounded top corners.
            let scale = min(size.height / 384, size.width / 300)
            let visibleHeight: CGFloat = isTallPortrait ? size.height / scale : 384
            let width = size.width / scale
            let sheetSize = CGSize(width: width, height: visibleHeight + 16)
            SheetView(sheet: entry.sheet, theme: entry.theme, calendarLayout: entry.calendarLayout, widgetSize: sheetSize)
                .frame(width: width, height: visibleHeight, alignment: .bottom).clipped()
                .scaleEffect(scale).frame(width: size.width, height: size.height)
        }
    }
    private var widgetDesign: Font.Design {
        entry.theme == .editorialDay ? .default : .serif
    }
    private func widgetPalette(theme: DailyTheme, page: PrintedDay) -> Color {
        if let t = theme.original { return t.accent(for: DayInfo(page: page)) }
        if theme == .tungShing {
            return PrintFace.dateInk(for: page)
        }
        return Color(red: 0.22, green: 0.12, blue: 0.10)
    }
    private func expandedList(_ title: String, _ side: ActivityPreference.Side, _ reading: Reading) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            entry.theme.activityHeading(title).font(.caption.weight(.black)).tracking(1)
            ForEach(reading.lines, id: \.self) { line in
                Text(verbatim: line).font(.system(.body, design: .serif)).lineLimit(2).minimumScaleFactor(0.85)
            }
            if reading.remaining > 0 { Text("+\(reading.remaining) more").font(.caption2) }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .activityLink(day: entry.sheet.label, side: side)
    }
    private func mediumReadings(_ page: PrintedDay, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            widgetList("宜  DO", page.recommended, count: count)
                .activityLink(day: entry.sheet.label, side: .recommended)
            widgetList("忌  AVOID", page.avoided, count: count)
                .activityLink(day: entry.sheet.label, side: .avoided)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func widgetList(_ title: String, _ reading: Reading, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            entry.theme.activityHeading(title).font(.caption.bold())
            Text(verbatim: reading.lines.prefix(count).joined(separator: " · ")).font(.caption2)
        }
    }
}

/// A square widget keeps the readings and the proverb together under a shorter date heading.
private struct CompactTungShing: View {
    let page: PrintedDay
    let dateInk: Color
    let ink: Color
    let paper: Color

    var body: some View {
        GeometryReader { area in
            let scale = min(area.size.width, area.size.height) / 160
            if scale > 0 {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        TungShingNumeral(day: Int(page.date.day), size: 48).foregroundStyle(dateInk)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(verbatim: String(monthNamesEN[Int(page.date.month)].prefix(3)) + " " + String(page.date.year))
                            Text(verbatim: page.report.weekdayLabel + " · " + page.report.lunarDayLabel)
                        }.font(.system(size: 12, weight: .bold))
                    }.frame(maxWidth: .infinity, alignment: .center)
                    Rectangle().fill(ink).frame(height: 1)
                    if let line = page.recommended.lines.first { Text(verbatim: "宜  Do · " + line) }
                    if let line = page.avoided.lines.first { Text(verbatim: "忌  Avoid · " + line) }
                    if let proverb = ChineseProverb.on(page.date) {
                        ProverbStrip(proverb: proverb, ink: ink, paper: paper, compact: true)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ink)
                .frame(width: area.size.width / scale, height: area.size.height / scale)
                .scaleEffect(scale, anchor: .topLeading)
            }
        }
    }
}

#if os(iOS)
/// Small, background-free presentation shared by CarPlay and StandBy.
struct DashboardAlmanac: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let page = entry.sheet.page {
            let info = DayInfo(page: page)
            let inks = dashboardInks(info)
            if entry.theme == .tungShing {
                CompactTungShing(page: page, dateInk: inks.date, ink: inks.rule,
                                 paper: colorScheme == .dark ? .black : .white)
            } else {
                dashboardFace(info, inks: inks)
            }
        } else {
            VStack(alignment: .leading, spacing: 5) {
                Text(verbatim: entry.sheet.label).font(.headline)
                Text(entry.sheet.loading ? "Daily Almanac" : "Almanac unavailable")
            }
            .foregroundStyle(.primary)
        }
    }

    private func dashboardFace(_ info: DayInfo, inks: (date: Color, rule: Color)) -> some View {
        GeometryReader { area in
            // Scale the print uniformly inside the margins supplied by the host.
            let scale = min(area.size.width, area.size.height) / 130
            if scale > 0 {
                ViewThatFits(in: .vertical) {
                    face(info, dateInk: inks.date, ruleInk: inks.rule, compact: false)
                    face(info, dateInk: inks.date, ruleInk: inks.rule, compact: true)
                }
                .frame(width: area.size.width / scale, height: area.size.height / scale, alignment: .leading)
                .scaleEffect(scale, anchor: .topLeading)
            }
        }
    }

    private func face(_ info: DayInfo, dateInk: Color, ruleInk: Color, compact: Bool) -> some View {
        let page = info.page
        return VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            masthead(info, dateInk: dateInk, ruleInk: ruleInk, compact: compact)
            .frame(height: compact ? 35 : 50)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(info.date, format: .dateTime.weekday(.wide).month(.wide).day().year()))
            Rectangle().fill(ruleInk).frame(height: 1.5).accessibilityHidden(true)
            if entry.theme == .tsukigoyomi {
                let reading = TsukigoyomiReading(page)
                Text(verbatim: reading.phase)
                if let season = reading.season {
                    Text(verbatim: season.term + "  ·  " + season.microseason).font(Theme.mincho(compact ? 13 : 15))
                }
            } else if entry.theme == .illyeok {
                let proverb = KoreanProverb.on(page.date.dayID.value)
                Text(verbatim: proverb.korean).font(.system(size: compact ? 12 : 14, weight: .semibold))
                Text(verbatim: proverb.english).font(.custom("Georgia", fixedSize: compact ? 10 : 12))
            } else if entry.theme == .nihon {
                let reading = NihonReading(page)
                Text(verbatim: reading.rokuyo + "  ·  " + reading.tide)
                Text(verbatim: reading.info.proverb.jp).font(Theme.mincho(compact ? 12 : 14)).lineLimit(2)
            } else if entry.theme == .moon {
                let moon = MoonReading(page, site: entry.sheet.skySite)
                Text(verbatim: moon.phase)
                Text(verbatim: moon.milestone?.name ?? moon.constellation.rawValue)
                    .foregroundStyle(ruleInk)
            } else if entry.theme == .fuji {
                let value = FujiReading(page)
                HStack(spacing: 5) {
                    if let sky = value.sky {
                        MoonDisc(sky: sky, ink: FujiFace.ink, paper: FujiFace.paper)
                            .frame(width: 18, height: 18)
                            .overlay { Circle().strokeBorder(.primary.opacity(0.5), lineWidth: 0.5) }
                    }
                    Text(verbatim: value.rokuyo ?? "—")
                }
                if let holiday = value.holidayLine { Text(verbatim: holiday).lineLimit(1).minimumScaleFactor(0.7) }
            } else if entry.theme == .celestialAlmanac {
                let value = CelestialReading(page)
                Text(verbatim: value.sign + " · " + value.tradition.dayAnimal)
                Text(verbatim: "Moon " + value.moon)
            } else if entry.calendarLayout && entry.theme.original != nil {
                Text(verbatim: page.report.weekdayLabel)
                Text(verbatim: info.lunarCaption)
            } else {
                if let line = page.recommended.lines.first { reading("宜", label: "Do", line: line) }
                if let line = page.avoided.lines.first { reading("忌", label: "Avoid", line: line) }
            }
        }
        .font(.system(size: compact ? 13 : 15, weight: .semibold))
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Use the source face's press ink and lift it for a dark dashboard.
    private func dashboardInks(_ info: DayInfo) -> (date: Color, rule: Color) {
        let red = Color(red: 0.74, green: 0.06, blue: 0.20)
        let green = Color(red: 0.03, green: 0.32, blue: 0.22)
        if entry.theme == .tungShing {
            let weekendInk = colorScheme == .dark ? Color(red: 1, green: 0.57, blue: 0.61) : red
            let weekdayInk = colorScheme == .dark ? Color(red: 0.53, green: 0.89, blue: 0.70) : green
            let dateInk = info.isSaturday || info.isSunday || info.page.holiday != nil ? weekendInk : weekdayInk
            return (dateInk, info.page.holiday == nil ? dateInk : weekdayInk)
        }

        let inks: (Color, Color)
        if entry.theme == .tsukigoyomi {
            inks = (TsukigoyomiFace.ink, TsukigoyomiBoard.indigo)
        } else if entry.theme == .illyeok {
            inks = (IllyeokReading(info.page).ink, Color(red: 0.12, green: 0.39, blue: 0.25))
        } else if entry.theme == .nihon {
            inks = (NihonFace.ink(info.weekday - 1, holiday: NihonReading(info.page).holiday != nil), NihonFace.blue)
        } else if entry.theme == .moon {
            inks = (MoonFace.ink, MoonFace.blue)
        } else if entry.theme == .fuji {
            inks = (FujiReading(info.page).redDate ? FujiFace.red : FujiFace.ink, FujiFace.ink)
        } else if entry.theme == .celestialAlmanac {
            inks = (CelestialFace.ink(weekday: info.weekday), CelestialFace.black)
        } else if let original = entry.theme.original {
            inks = (original.accent(for: info), entry.theme == .koyomi ? original.accentRed : original.ink)
        } else {
            let umber = Color(red: 0.16, green: 0.11, blue: 0.09)
            inks = (umber, entry.theme == .deskLedger ? umber : Ink.vermilion)
        }
        func legible(_ ink: Color) -> Color {
            colorScheme == .dark ? ink.mix(with: .white, by: 0.76) : ink.mix(with: .black, by: 0.12)
        }
        return (legible(inks.0), legible(inks.1))
    }

    @ViewBuilder private func masthead(_ info: DayInfo, dateInk: Color, ruleInk: Color, compact: Bool) -> some View {
        let size: CGFloat = compact ? 36 : 52
        let month = String(monthNamesEN[info.month].prefix(3))
        let day = Text(verbatim: String(info.day))
        let weekday = Text(verbatim: info.weekdayEN)
        let monthLabel = Text(verbatim: month)
        let captions = VStack(alignment: .leading, spacing: 0) { monthLabel; weekday }
        let serifDay = day.font(Theme.numeral(size)).foregroundStyle(dateInk)
        Group {
            switch entry.theme {
            case .tungShing:
                HStack(spacing: 7) {
                    TungShingNumeral(day: info.day, size: size).foregroundStyle(dateInk)
                    captions
                }
            case .illyeok:
                HStack(spacing: 7) {
                    IllyeokNumeral(day: info.day, ink: dateInk).frame(width: size, height: size * 0.8)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: String(info.month) + "월")
                        Text(verbatim: IllyeokReading(info.page).weekday)
                    }
                }
            case .nihon:
                HStack(spacing: 5) {
                    NihonNumber(day: info.day).fill(dateInk).frame(width: size * 0.95, height: size * 0.78)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: String(info.month) + "月")
                        Text(verbatim: String(info.weekdayKanji.prefix(2)))
                    }.font(Theme.kanji(13))
                }
            case .moon, .tsukigoyomi:
                HStack(spacing: 6) {
                    if let sky = entry.theme == .tsukigoyomi ? TsukigoyomiReading(info.page).sky : MoonReading(info.page).sky {
                        MoonDisc(sky: sky, ink: ruleInk, paper: colorScheme == .dark ? .black : .white)
                            .frame(width: size * 0.45, height: size * 0.45)
                    }
                    day.font(.system(size: size * 0.78, weight: .bold)).foregroundStyle(dateInk)
                    captions.font(.system(size: 10))
                }
            case .fuji:
                HStack(spacing: 7) {
                    day.font(.custom("HelveticaNeue-Medium", fixedSize: size)).foregroundStyle(dateInk)
                    captions.font(.system(size: 12))
                }
            case .celestialAlmanac:
                HStack(spacing: 7) {
                    CelestialNumeral(day: info.day, height: size * 0.93).foregroundStyle(dateInk)
                    captions.font(.system(size: 12, weight: .medium, design: .monospaced))
                }
            case .showa:
                HStack(spacing: 4) {
                    weekday.font(.system(size: 11, weight: .bold, design: .serif))
                    Spacer(minLength: 0)
                    serifDay
                    Spacer(minLength: 0)
                    monthLabel.font(.system(size: 11, weight: .bold, design: .serif))
                }
            case .editorialDay:
                HStack(spacing: 4) {
                    serifDay
                    Spacer(minLength: 2)
                    captions.tracking(1.5)
                }
            case .koyomi:
                HStack(spacing: 6) {
                    Text(verbatim: kanjiNumber(info.day)).font(Theme.mincho(size * 0.72)).foregroundStyle(dateInk)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: month + " " + String(info.day))
                        weekday
                    }.font(.system(size: 12, weight: .bold, design: .serif))
                }
            case .huangli, .tongsheng:
                HStack(spacing: 5) {
                    serifDay
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 2) {
                        monthLabel
                        if entry.theme == .huangli {
                            weekday.padding(.horizontal, 4).foregroundStyle(colorScheme == .dark ? Color.black : .white)
                                .background(ruleInk)
                        } else {
                            weekday.italic()
                        }
                    }.font(.system(size: 13, weight: .bold, design: .serif))
                }
            case .deskLedger:
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        monthLabel
                        weekday.foregroundStyle(DailyTheme.ledgerInk(onDarkPaper: colorScheme == .dark))
                    }
                    Spacer(minLength: 0)
                    serifDay
                }
            case .almanacColumns:
                HStack(spacing: 5) {
                    monthLabel
                    Rectangle().fill(ruleInk).frame(width: 1, height: size * 0.6)
                    serifDay
                    Rectangle().fill(ruleInk).frame(width: 1, height: size * 0.6)
                    weekday
                }.font(.system(size: 11, weight: .bold, design: .serif))
            }
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(ruleInk)
    }

    private func reading(_ mark: String, label: String, line: String) -> some View {
        HStack(alignment: .center, spacing: 5) {
            VStack(spacing: 0) {
                entry.theme.activityHeading(mark, onDarkPaper: colorScheme == .dark).font(.system(size: 14, weight: .bold))
                Text(verbatim: label.uppercased()).font(.system(size: 9, weight: .bold)).fixedSize()
            }.frame(width: 29)
            Text(verbatim: line).lineLimit(3).minimumScaleFactor(0.85)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label + ", " + line))
    }
}
#endif
