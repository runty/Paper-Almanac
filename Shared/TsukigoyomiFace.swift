import SwiftUI
import TungShingDailyAlmanac

struct TsukigoyomiReading {
    let almanac: NihonReading
    let season: JapaneseSeason?
    let sky: CelestialSky?

    init(_ page: PrintedDay) {
        almanac = NihonReading(page)
        season = JapaneseSeason(on: page.date)
        sky = try? CelestialSky.atJapaneseNoon(on: page.date)
    }

    var info: DayInfo { almanac.info }
    var phase: String { MoonReading.phase(of: sky) }
    var dateLine: String { "\(info.month)月\(info.day)日" }
    var lunarDate: String? {
        guard let date = almanac.traditions.kyureki else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .spellOut
        let day = formatter.string(from: NSNumber(value: date.day)) ?? String(date.day)
        return (date.isLeapMonth ? "閏" : "") + NihonReading.months[Int(date.month) - 1] + day + "日"
    }

    var summary: String {
        [info.page.date.label, almanac.traditions.rokuyo.map { "六曜 " + $0 }, phase, almanac.tide, almanac.age.map { "Lunar age " + $0 }, lunarDate,
         season?.term, season?.termEnglish, season?.microseason, season?.microseasonEnglish]
            .compactMap { $0 }.joined(separator: ". ")
    }
}

struct TsukigoyomiBoard: View {
    static let indigo = Color(red: 0.083, green: 0.151, blue: 0.234)

    var body: some View {
        GeometryReader { box in
            let header = min(box.size.height * 0.10, 35)
            ZStack(alignment: .top) {
                LinearGradient(colors: [Self.indigo, Color(red: 0.145, green: 0.251, blue: 0.351), Self.indigo],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                PaperGrain(seed: 72, strength: 0.8)
                HStack(spacing: 7) {
                    ForEach(0..<9) { i in
                        ZStack {
                            Circle().strokeBorder(.white.opacity(0.46), lineWidth: 0.45)
                            IlluminatedLimb(fraction: 1 - abs(Double(i - 4)) / 4, waxing: i < 4)
                                .fill(Color(red: 0.89, green: 0.79, blue: 0.58))
                        }.frame(width: 7, height: 7)
                    }
                }.frame(height: header)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .accessibilityHidden(true)
    }
}

struct TsukigoyomiFace: View {
    let reading: TsukigoyomiReading
    var widget = false
    static let paper = Color(red: 0.985, green: 0.978, blue: 0.949)
    static let ink = Color(red: 0.15, green: 0.145, blue: 0.15)
    private static let accent = Color(red: 0.26, green: 0.32, blue: 0.39)

    var body: some View {
        GeometryReader { box in
            let size = box.size
            ZStack {
                Self.paper
                if size.width > size.height * 1.4 {
                    let u = min(size.width / 320, size.height / 150)
                    HStack(spacing: 14 * u) {
                        lunarDisk.frame(width: 92 * u, height: 92 * u)
                        VStack(spacing: 5 * u) {
                            compactDate(19 * u)
                            Text(verbatim: reading.phase).font(Theme.mincho(11 * u))
                            seasonNote(u)
                        }
                    }.padding(.horizontal, 12 * u)
                } else if widget && size.height < 220 {
                    let u = min(size.width, size.height) / 158
                    VStack(spacing: 3 * u) {
                        compactDate(16 * u)
                        lunarDisk.frame(width: 53 * u, height: 53 * u)
                        Text(verbatim: reading.phase).font(Theme.mincho(10 * u))
                        seasonNote(u)
                    }.padding(.horizontal, 7 * u)
                } else {
                    fullPage(min(size.width / 300, size.height / 400))
                }
            }.foregroundStyle(Self.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reading.summary)
    }

    private var lunarDisk: some View {
        ZStack {
            if let sky = reading.sky {
                Circle().fill(Self.ink)
                IlluminatedLimb(fraction: sky.moonIllumination, waxing: sky.moonIsWaxing)
                    .fill(Color(red: 0.998, green: 0.988, blue: 0.954))
                PaperGrain(seed: 29, strength: 1).clipShape(Circle())
                Circle().strokeBorder(Self.ink, lineWidth: 1)
            }
        }.aspectRatio(1, contentMode: .fit)
    }

    private func compactDate(_ size: CGFloat) -> some View {
        Text(verbatim: reading.dateLine + "  " + reading.almanac.weekday)
            .font(Theme.mincho(size)).dayNumberTarget()
    }

    private func seasonNote(_ u: CGFloat) -> some View {
        VStack(spacing: 2 * u) {
            if let season = reading.season {
                Text(verbatim: season.term + "  ·  " + season.microseason).font(Theme.mincho(13 * u))
                Text(verbatim: season.microseasonEnglish).font(.system(size: 10 * u, design: .serif))
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.85)
            }
        }
    }

    private func fullPage(_ u: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                if let season = reading.season {
                    VStack(spacing: 7 * u) {
                        VerticalText("二十四節気", font: Theme.mincho(8.5 * u), color: Self.accent)
                        VerticalText(season.term, font: Theme.mincho(11 * u), color: Self.ink)
                    }.frame(width: 22 * u)
                }
                Spacer(minLength: 5 * u)
                VStack(spacing: 8 * u) {
                    lunarDisk.frame(width: 164 * u, height: 164 * u)
                    Text(verbatim: reading.phase).font(.custom("Georgia", fixedSize: 12 * u))
                        .fixedSize(horizontal: true, vertical: false)
                    Text(verbatim: [reading.almanac.tide, reading.almanac.age.map { "月齢 " + $0 }]
                        .compactMap { $0 }.joined(separator: "   "))
                        .font(Theme.mincho(11 * u))
                }.padding(.top, 9 * u)
                Spacer(minLength: 5 * u)
                VStack(spacing: 7 * u) {
                    VerticalText("旧暦", font: Theme.mincho(8.5 * u), color: Self.accent)
                    VerticalText(reading.lunarDate ?? "—", font: Theme.mincho(11 * u), color: Self.ink)
                }.frame(width: 22 * u)
            }
            Spacer(minLength: 5 * u)
            if let season = reading.season {
                Text(verbatim: season.termEnglish.uppercased() + "   ·   七十二候  " + String(format: "%02d", season.number) + " / 72")
                    .font(.system(size: 8.5 * u, weight: .medium)).tracking(u).foregroundStyle(Self.accent)
                VStack(spacing: 2 * u) {
                    Text(verbatim: season.microseason).font(Theme.mincho(15 * u))
                    Text(verbatim: season.microseasonEnglish).font(.custom("Georgia-Italic", fixedSize: 11 * u))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 9 * u)
            }
            Spacer(minLength: 4 * u)
            Rectangle().fill(Self.ink).frame(height: 0.7 * u)
            dateFooter(u).padding(.top, 7 * u)
        }
        .padding(.horizontal, 19 * u)
        .padding(.top, (widget ? 15 : 34) * u)
        .padding(.bottom, 29 * u)
    }

    private func dateFooter(_ u: CGFloat) -> some View {
        let yearFont = Font.custom("TimesNewRomanPSMT", fixedSize: 25 * u)
        let year = Text(verbatim: String(reading.info.year)).font(yearFont)
        let weekday = Text(verbatim: reading.almanac.weekday + "日").font(Theme.mincho(18 * u))
        let weekdayCaption = [reading.info.weekdayEN.uppercased()] + (reading.almanac.traditions.rokuyo ?? "").map(String.init)

        return HStack(alignment: .lastTextBaseline, spacing: 4 * u) {
            Grid(verticalSpacing: 0) {
                footerCaption(reading.info.eraYear.map(String.init), scale: u)
                GridRow { year }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 6 * u) {
                dateComponent(reading.info.month, unit: "月", scale: u)
                dateComponent(reading.info.day, unit: "日", scale: u)
            }
            .fixedSize()
            .dayNumberTarget()

            Grid(verticalSpacing: 0) {
                footerCaption(weekdayCaption, scale: u)
                GridRow {
                    // Reserve the year's line metrics so both captions sit on the same baseline.
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        year.hidden().frame(width: 0).accessibilityHidden(true)
                        weekday
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .lineLimit(1)
    }

    private func footerCaption(_ parts: [String], scale u: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(parts.indices, id: \.self) { i in
                if i > 0 { Spacer(minLength: 0) }
                Text(verbatim: parts[i])
            }
        }
        .font(Theme.mincho(8 * u))
        .gridCellUnsizedAxes(.horizontal)
    }

    private func dateComponent(_ value: Int, unit: String, scale u: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2 * u) {
            Text(verbatim: String(value)).font(.custom("TimesNewRomanPSMT", fixedSize: 39 * u))
            Text(verbatim: unit).font(Theme.mincho(17 * u))
        }
    }
}
