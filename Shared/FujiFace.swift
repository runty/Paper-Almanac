import SwiftUI
import TungShingDailyAlmanac

struct FujiReading {
    let info: DayInfo
    let holiday: String?
    let rokuyo: String?
    let romanization: String?
    let sky: CelestialSky?

    init(_ page: PrintedDay) {
        info = DayInfo(page: page)
        holiday = FujiHolidays.name(on: page.date)
        let traditions = CelestialTraditions(report: page.report)
        rokuyo = traditions.rokuyo
        romanization = traditions.rokuyoRomanized
        sky = try? CelestialSky(date: page.date)
    }

    static var sourceNotes: String {
        FujiHolidays.attribution ?? "Japanese holiday data unavailable."
    }
    var holidayLine: String? {
        guard let coverage = FujiHolidays.coverage else { return "Holiday data unavailable" }
        if !coverage.contains(info.year) { return "Holiday data covers " + String(coverage.lowerBound) + "–" + String(coverage.upperBound) }
        return holiday
    }
    var redDate: Bool { holiday != nil || info.isSunday }
    var weekday: String { weekdayNamesEN[info.weekday].uppercased() }
    var monthYear: String { String(monthNamesEN[info.month].prefix(3)).capitalized + " " + String(info.year) }
    var moonDescription: String? {
        sky.map {
            ($0.moonIsWaxing ? "Waxing moon" : "Waning moon") + ", " +
            String(Int(($0.moonIllumination * 100).rounded())) + "% illuminated"
        }
    }
    var summary: String {
        [info.page.date.label, weekday, holidayLine, rokuyo, romanization, moonDescription].compactMap { $0 }.joined(separator: ". ")
    }
}

struct FujiFace: View {
    let reading: FujiReading
    var widget = false
    static let paper = Color(red: 0.979, green: 0.965, blue: 0.922)
    static let ink = Color(red: 0.215, green: 0.209, blue: 0.191)
    static let red = Color(red: 0.91, green: 0.314, blue: 0.237)

    var body: some View {
        GeometryReader { box in
            let h = box.size.height
            let scale = min(box.size.width / 300, h / (widget ? 335 : 400))
            let compact = widget && h < 220
            let margin = max(compact ? 14.0 : 20.0, scale * 28)
            ZStack {
                Self.paper
                PaperGrain(seed: reading.info.dayOfYear, strength: 0.48)
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        Text(verbatim: String(reading.info.month)).font(.custom("HelveticaNeue", fixedSize: max(15, 30 * scale)))
                        Spacer()
                        Text(verbatim: "日めくり\nカレンダー")
                            .font(.system(size: max(8, 15 * scale), weight: .bold))
                            .fixedSize()
                    }
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2 * scale) {
                            Text(verbatim: reading.rokuyo ?? "—").font(.system(size: max(10, 16 * scale), design: .serif))
                            Text(verbatim: reading.monthYear).font(.custom("HelveticaNeue", fixedSize: max(13, 24 * scale)))
                        }
                        Spacer()
                        if let sky = reading.sky {
                            MoonDisc(sky: sky, ink: Self.ink, paper: Self.paper)
                                .frame(width: max(15, 23 * scale), height: max(15, 23 * scale))
                                .padding(.bottom, 4 * scale)
                        }
                    }
                }
                .padding(.horizontal, margin)
                .padding(.top, widget ? margin * 0.75 : 48 * scale)
                .padding(.bottom, widget ? margin * 0.69 : 22 * scale)
                VStack(spacing: 1 * scale) {
                    Text(verbatim: String(reading.info.day))
                        .font(.custom("HelveticaNeue-Medium", fixedSize: (compact ? 126 : 150) * scale))
                        .kerning(-4 * scale)
                        .fixedSize().padding(.horizontal, 4 * scale)
                        .foregroundStyle(reading.redDate ? Self.red : Self.ink)
                        .dayNumberTarget()
                        .padding(.bottom, -7 * scale)
                    Text(verbatim: reading.weekday).font(.custom("HelveticaNeue", fixedSize: max(11, 20 * scale)))
                    Text(verbatim: reading.holidayLine ?? " ")
                        .font(.system(size: max(9, 15 * scale))).lineLimit(1).minimumScaleFactor(0.75)
                }
                .offset(y: widget ? -2 * scale : -4 * scale)
            }
        }
        .foregroundStyle(Self.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reading.summary)
    }
}

/// The aligned cut edges of the remaining sheets sit just below the top page.
struct FujiPaperStack: View {
    let remainingFraction: Double
    var paper = FujiFace.paper
    var edge = Color.gray
    var body: some View {
        #if os(macOS)
        let depth = 16 * remainingFraction
        #else
        let depth = 2 + 4 * remainingFraction
        #endif
        ZStack {
            ForEach([1.0, 0.68, 0.36], id: \.self) { fraction in
                RoundedRectangle(cornerRadius: 1)
                    .fill(paper.mix(with: edge, by: 0.16 + 0.3 * fraction))
                    .offset(y: Metrics.pageTopInset + depth * fraction)
            }
        }.frame(width: Metrics.pageW - 1, height: Metrics.pageH)
            .allowsHitTesting(false)
    }
}

/// A folded metal clip spans the top of the sheet.
struct FujiClip: View {
    var height: CGFloat = Metrics.bindingH + 11

    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: 1, bottomLeadingRadius: 6,
                               bottomTrailingRadius: 6, topTrailingRadius: 1)
            .fill(LinearGradient(colors: [.white, Color(white: 0.86), Color(white: 0.82)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.9)).frame(height: 1) }
            .frame(width: Metrics.pageW, height: height)
            .shadow(color: .black.opacity(0.23), radius: 0.8, y: 1)
    }
}
