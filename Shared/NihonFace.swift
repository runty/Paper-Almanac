import CoreText
import SwiftUI
import TungShingDailyAlmanac

struct NihonReading {
    let info: DayInfo
    let traditions: CelestialTraditions
    let holiday: String?
    let age: String?
    let tomorrow: GregorianDate?

    init(_ page: PrintedDay) {
        info = DayInfo(page: page)
        traditions = CelestialTraditions(report: page.report)
        holiday = FujiHolidays.name(on: page.date)
        age = CelestialSky.lunarAgeAtJapaneseNoon(on: page.date).map { String(format: "%.1f", $0) }
        tomorrow = page.date < DailyAlmanacReader.lastDate ? try? page.date.adding(days: 1) : nil
    }

    var oldDate: String {
        guard let lunar = traditions.kyureki else { return "旧暦 —" }
        return "旧" + (lunar.isLeapMonth ? "閏" : "") + "\(lunar.month)月\(lunar.day)日"
    }

    var monthName: String { Self.months[info.month - 1] }
    static let months = ["睦月", "如月", "弥生", "卯月", "皐月", "水無月", "文月", "葉月", "長月", "神無月", "霜月", "師走"]
    var weekday: String { String(info.weekdayKanji.prefix(2)) }
    var rokuyo: String { traditions.rokuyo ?? "—" }
    var mansion: String { traditions.nijuhasshuku ?? "—" }
    var tide: String { traditions.tideName ?? "—" }
    var summary: String {
        [info.page.date.label, weekday, holiday, oldDate,
         "六曜 " + rokuyo + " " + (traditions.rokuyoRomanized ?? ""),
         "二十八宿 " + mansion, "月齢 " + (age ?? "—"), "潮名 " + tide,
         info.proverb.jp, info.proverb.en].compactMap { $0 }.joined(separator: ". ")
    }
}

struct NihonFace: View {
    let reading: NihonReading
    var widget = false
    var goldFortune = false
    private var stock: Color { goldFortune ? Kinun.paper : Self.paper }
    static let paper = Color(red: 0.994, green: 0.989, blue: 0.967)
    static let black = Color(red: 0.115, green: 0.112, blue: 0.106)
    static let blue = Color(red: 0.12, green: 0.32, blue: 0.62)
    static let red = Color(red: 0.86, green: 0.235, blue: 0.17)
    static func ink(_ weekday: Int, holiday: Bool) -> Color {
        holiday || weekday == 0 ? red : weekday == 6 ? blue : black
    }
    private var ink: Color { Self.ink(reading.info.weekday - 1, holiday: reading.holiday != nil) }

    var body: some View {
        GeometryReader { box in
            let size = box.size
            let wide = size.width > size.height * 1.4
            let compact = widget && size.height < 220
            let u = min(size.width / 300, size.height / 400)
            ZStack {
                stock
                PaperGrain(seed: reading.info.dayOfYear, strength: 0.75)
                let marked = goldFortune && Kinun.isGrainDay(reading.info.page)
                if wide {
                    let k = min(size.width / 320, size.height / 155)
                    HStack(spacing: 13 * k) {
                        VStack(spacing: 2 * k) {
                            Text(verbatim: "\(reading.info.month)月").font(Theme.mincho(14 * k))
                            number.frame(height: 76 * k)
                            weekday(21 * k)
                        }.frame(width: size.width * 0.36)
                        VStack(spacing: 6 * k) {
                            Text(verbatim: reading.oldDate).font(Theme.mincho(12 * k)).foregroundStyle(Self.red)
                            readings(k)
                            saying(k)
                            if marked { grainSeal(k) }
                        }
                    }.padding(.horizontal, 12 * k)
                } else if compact {
                    let k = min(size.width, size.height) / 158
                    VStack(spacing: 2 * k) {
                        Text(verbatim: "\(reading.info.month)月  ·  " + reading.weekday)
                            .font(Theme.kanji(13 * k)).foregroundStyle(ink)
                        number.frame(width: 96 * k, height: 66 * k)
                        Text(verbatim: reading.rokuyo + "  ·  " + reading.tide)
                            .font(Theme.mincho(12 * k))
                        if marked { grainSeal(k) } else { Text(verbatim: reading.info.proverb.jp).font(Theme.mincho(10 * k)) }
                    }
                } else {
                    VStack(spacing: 0) {
                        header(u)
                        ZStack(alignment: .trailing) {
                            number.padding(.horizontal, (reading.holiday == nil ? 7 : 23) * u)
                            if let holiday = reading.holiday {
                                VerticalText(holiday, font: Theme.kanji(13 * u), color: Self.red, spacing: 0)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                        }.frame(maxHeight: .infinity).padding(.vertical, 6 * u)
                        weekday(33 * u)
                        Text(verbatim: reading.oldDate).font(Theme.mincho(15 * u)).foregroundStyle(Self.red)
                        Rectangle().fill(Self.black).frame(height: u).padding(.vertical, 5 * u)
                        readings(u)
                        saying(u).padding(.top, 4 * u)
                        if marked { grainSeal(u).padding(.top, 3 * u) }
                    }
                    .padding(.horizontal, max(12, 14 * u))
                    .padding(.top, (widget ? 13 : 32) * u)
                    .padding(.bottom, 13 * u)
                }
            }.foregroundStyle(Self.black)
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .accessibilityElement(children: .ignore).accessibilityLabel(goldFortune ? Kinun.summary(reading) : reading.summary)
    }

    private func grainSeal(_ u: CGFloat) -> some View {
        let ornament = KinunHarvestMark()
            .stroke(style: StrokeStyle(lineWidth: u, lineCap: .round, lineJoin: .round))
            .frame(width: 34 * u, height: 17 * u)
            .accessibilityHidden(true)
        return HStack(spacing: 5 * u) {
            ornament
            Text(verbatim: Kinun.grainDay).font(Theme.kanji(13 * u))
            ornament.scaleEffect(x: -1, y: 1)
        }.foregroundStyle(Kinun.seal)
    }

    private func weekday(_ size: CGFloat) -> some View {
        Text(verbatim: reading.weekday)
            .font(.custom("HiraginoSans-W8", fixedSize: size))
            .scaleEffect(x: 1.13, y: 1)
            .foregroundStyle(ink)
    }

    private func header(_ u: CGFloat) -> some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: goldFortune ? .firstTextBaseline : .center)) {
            HStack(alignment: goldFortune ? .firstTextBaseline : .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: String(reading.info.year)).font(.system(size: 17 * u, weight: .bold, design: .serif))
                    Text(verbatim: reading.monthName).font(Theme.mincho(13 * u)).foregroundStyle(Self.blue)
                }
                Spacer()
                Text(verbatim: reading.info.eraYear).font(Theme.mincho(13 * u))
            }
            Text(verbatim: "\(reading.info.month)月").font(Theme.mincho(28 * u))
        }
    }

    private var number: some View {
        ZStack {
            if let tomorrow = reading.tomorrow {
                NihonNumber(day: Int(tomorrow.day))
                    .foregroundStyle(Self.ink(tomorrow.weekdaySunday0, holiday: FujiHolidays.name(on: tomorrow) != nil).opacity(0.082))
                    .offset(x: -2, y: -2)
            }
            NihonNumber(day: reading.info.day).foregroundStyle(ink)
        }.dayNumberTarget()
    }

    private func readings(_ u: CGFloat) -> some View {
        let mansionLabel = Text("二十八宿").font(Theme.mincho((goldFortune ? 10 : 8) * u))
        return HStack(alignment: goldFortune ? .top : .center, spacing: 6 * u) {
            VStack(spacing: u) {
                if goldFortune {
                    Text(verbatim: reading.mansion).font(Theme.mincho(19 * u))
                        .frame(width: 23 * u, height: 23 * u)
                        .border(Self.black, width: 0.8 * u)
                    mansionLabel
                } else {
                    mansionLabel
                    Text(verbatim: reading.mansion).font(Theme.mincho(22 * u))
                        .padding(.horizontal, 4 * u).border(Self.black, width: 0.8 * u)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "六曜   " + reading.rokuyo).font(Theme.kanji(13 * u))
                Text(verbatim: "月齢   " + (reading.age ?? "—")).font(Theme.mincho(12 * u))
            }
            Spacer(minLength: 0)
            VStack(spacing: u) {
                ZStack {
                    Rectangle().fill(Self.blue)
                    if goldFortune, let sky = try? CelestialSky.atJapaneseNoon(on: reading.info.page.date) {
                        MoonDisc(sky: sky, ink: Self.blue, paper: stock)
                            .overlay { Circle().strokeBorder(stock, lineWidth: 0.8 * u) }
                            .padding(u)
                    } else {
                        Circle().fill(stock).padding(2 * u)
                        Image(systemName: "water.waves").font(.system(size: 13 * u, weight: .medium)).foregroundStyle(Self.blue)
                    }
                }.frame(width: 23 * u, height: 23 * u)
                Text(verbatim: reading.tide).font(Theme.mincho(10 * u))
            }
        }
    }

    private func saying(_ u: CGFloat) -> some View {
        VStack(spacing: u) {
            Text(verbatim: reading.info.proverb.jp).font(Theme.mincho(14 * u))
            Text(verbatim: reading.info.proverb.en).font(.system(size: 9.5 * u, design: .serif)).multilineTextAlignment(.center)
        }.fixedSize(horizontal: false, vertical: true)
    }
}

/// Fit the ink bounds to the date field, independent of font ascenders and leading.
struct NihonNumber: Shape {
    let day: Int
    private static let font = CTFontCreateWithName("GillSans-Bold" as CFString, 100, nil)
    private static let angledOne = CTFontCreateWithName("AvenirNextCondensed-Bold" as CFString, 100, nil)
    // The calendar’s nine has a long curved tail and an upright cut at its end.
    private static let nine: CGPath = {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 13, y: 0))
        p.addCurve(to: CGPoint(x: 66, y: 58), control1: CGPoint(x: 45, y: 0), control2: CGPoint(x: 66, y: 22))
        p.addCurve(to: CGPoint(x: 33, y: 100), control1: CGPoint(x: 66, y: 85), control2: CGPoint(x: 55, y: 100))
        p.addCurve(to: CGPoint(x: 0, y: 65), control1: CGPoint(x: 13, y: 100), control2: CGPoint(x: 0, y: 86))
        p.addCurve(to: CGPoint(x: 30, y: 32), control1: CGPoint(x: 0, y: 44), control2: CGPoint(x: 12, y: 32))
        p.addQuadCurve(to: CGPoint(x: 45, y: 36), control: CGPoint(x: 39, y: 32))
        p.addQuadCurve(to: CGPoint(x: 13, y: 17), control: CGPoint(x: 38, y: 18))
        p.closeSubpath()
        p.move(to: CGPoint(x: 47, y: 65))
        p.addCurve(to: CGPoint(x: 33, y: 50), control1: CGPoint(x: 47, y: 56), control2: CGPoint(x: 42, y: 50))
        p.addCurve(to: CGPoint(x: 19, y: 65), control1: CGPoint(x: 24, y: 50), control2: CGPoint(x: 19, y: 56))
        p.addCurve(to: CGPoint(x: 33, y: 82), control1: CGPoint(x: 19, y: 75), control2: CGPoint(x: 24, y: 82))
        p.addCurve(to: CGPoint(x: 47, y: 65), control1: CGPoint(x: 42, y: 82), control2: CGPoint(x: 47, y: 75))
        p.closeSubpath()
        return p
    }()

    func path(in rect: CGRect) -> Path {
        var ink = Path()
        for digit in String(day).utf16 {
            var character = digit, glyph = CGGlyph()
            let face = digit == 49 ? Self.angledOne : Self.font
            guard CTFontGetGlyphsForCharacters(face, &character, &glyph, 1),
                  let outline = digit == 57 ? Self.nine : CTFontCreatePathForGlyph(face, glyph, nil) else { continue }
            let bounds = outline.boundingBoxOfPath
            guard bounds.height > 0 else { continue }
            let scale = 100 / bounds.height
            let start = ink.isEmpty ? 0 : ink.boundingRect.maxX + 5
            ink.addPath(Path(outline), transform: CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                                                                    tx: start - bounds.minX * scale, ty: -bounds.minY * scale))
        }
        let b = ink.boundingRect
        guard b.width > 0, b.height > 0 else { return Path() }
        let width = min(rect.width, rect.height * b.width / b.height * 0.96)
        return ink.applying(CGAffineTransform(a: width / b.width, b: 0, c: 0, d: -rect.height / b.height,
                                              tx: rect.midX - width / 2, ty: rect.minY + b.maxY * rect.height / b.height))
    }
}
