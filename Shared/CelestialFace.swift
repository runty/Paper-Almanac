import SwiftUI
import TungShingDailyAlmanac

struct CelestialReading {
    let info: DayInfo
    let tradition: CelestialTraditions
    let sky: CelestialSky?
    let history: CelestialHistory.Entry

    init(_ page: PrintedDay) {
        info = DayInfo(page: page)
        tradition = CelestialTraditions(report: page.report)
        sky = try? CelestialSky(date: page.date)
        history = CelestialHistory.entry(on: page.date)
    }

    static let signs = ["Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
    static let glyphs = Array("♈♉♊♋♌♍♎♏♐♑♒♓")
    var sign: String { sky.map { Self.signs[$0.sunSignIndex] } ?? "—" }
    var moon: String { sky.map { String(Int(($0.moonIllumination * 100).rounded())) + "% lit" } ?? "—" }
    var moonAge: String? {
        // The printed diary records completed tenths of a day.
        sky?.elapsedMoonAgeDays.map { String(format: "%.1f", floor($0 * 10) / 10) }
    }
    var moonCaption: String {
        guard let age = moonAge, let sky else { return moon }
        return age + " d · " + String(Int((sky.moonIllumination * 100).rounded())) + "%"
    }
    var daylight: String {
        guard let minutes = sky?.tokyoDaylightMinutes else { return "—" }
        return String(format: "%dh %02dm", minutes / 60, minutes % 60)
    }
    var week: Int {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = CivilDay.calendar().timeZone
        return calendar.component(.weekOfYear, from: info.date)
    }
    var launchCredit: String? {
        history.sourceID.hasPrefix("GCAT ") ? history.sourceID + " · J. McDowell · CC BY 4.0" : nil
    }
    var nineStar: String {
        guard let n = tradition.dayNineStar else { return "—" }
        return ["一白水星","二黒土星","三碧木星","四緑木星","五黄土星","六白金星","七赤金星","八白土星","九紫火星"][n-1]
    }
    var japaneseDate: String {
        guard let lunar = tradition.kyureki else { return "—" }
        return (lunar.isLeapMonth ? "閏" : "") + String(lunar.month) + "/" + String(lunar.day)
    }
    var calendarNote: String {
        [tradition.kyurekiConventionNote, tradition.kyurekiBoundarySensitive
            ? "A modeled new moon near midnight makes the Japanese month boundary sensitive." : nil]
            .compactMap { $0 }.joined(separator: " ")
    }
    var japaneseMonthName: String {
        ["睦月", "如月", "弥生", "卯月", "皐月", "水無月", "文月", "葉月", "長月", "神無月", "霜月", "師走"][info.month - 1]
    }
    var guardianMark: String {
        switch tradition.guardian {
        case "Azure Dragon": "東"
        case "Black Tortoise": "北"
        case "White Tiger": "西"
        case "Vermilion Bird": "南"
        default: "—"
        }
    }
    var summary: String {
        let readings = [
            "Japanese old calendar (UTC+9) " + japaneseDate + ". Rokuyō " + (tradition.rokuyoRomanized ?? "unavailable") + ". Nine Star " + nineStar,
            "Hong Kong lunar date (UTC+8) " + info.lunarCaption + ". " + info.report.dayPillar.label + ". " + tradition.dayAnimal + ". " + tradition.guardian + ". " + tradition.mansionEnglish,
            "Approximate sky at noon UTC, 9 pm Tokyo. Tropical Sun in " + sign + ". Moon " + moon + ". Tokyo daylight " + daylight,
            moonAge.map { $0 + " days since new moon" } ?? "",
            String(history.year) + ". " + history.text, launchCredit ?? "", calendarNote
        ]
        return readings.filter { !$0.isEmpty }.joined(separator: ". ")
    }
}

struct CelestialFace: View {
    let reading: CelestialReading
    @Environment(\.isWidgetSheet) private var widget
    private var info: DayInfo { reading.info }
    static let black = Color(red: 0.085, green: 0.079, blue: 0.10)
    static let blue = Color(red: 0.02, green: 0.34, blue: 0.73)
    static let red = Color(red: 0.85, green: 0.19, blue: 0.17)
    static let paper = Color(red: 0.998, green: 0.994, blue: 0.986)
    static func ink(weekday: Int) -> Color { weekday == 1 ? red : weekday == 7 ? blue : black }
    private var ink: Color { Self.ink(weekday: info.weekday) }

    var body: some View {
        VStack(spacing: 0) {
            caption("CELESTIAL ALMANAC  " + String(info.year), size: 7.2).tracking(0.9)
            Text(verbatim: weekdayNamesEN[info.weekday].uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded)).tracking(0.9).foregroundStyle(ink)
                .padding(.top, 4)
            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    vertical(info.weekdayKanji).foregroundStyle(ink)
                    Spacer(minLength: 3)
                    metric(reading.tradition.rokuyo ?? "—", reading.tradition.rokuyoRomanized ?? "Rokuyō")
                    if let star = reading.tradition.dayNineStar {
                        starSeal(star)
                    }
                    metric(reading.nineStar, "NINE STAR")
                }.frame(width: 48)
                VStack(spacing: 2) {
                    ZStack {
                        ForEach([2, 1], id: \.self) { offset in
                            if let next = try? info.page.date.adding(days: Int64(offset)) {
                                CelestialNumeral(day: Int(next.day), height: 111)
                                    .foregroundStyle(Self.ink(weekday: next.weekdaySunday0 + 1))
                                    .opacity(offset == 1 ? 0.09 : 0.035)
                                    .offset(x: CGFloat(offset) * 2.5, y: CGFloat(offset))
                                    .accessibilityHidden(true)
                            }
                        }
                        CelestialNumeral(day: info.day, height: 111).foregroundStyle(ink).dayNumberTarget()
                    }
                    Text(verbatim: monthNamesEN[info.month].uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded)).tracking(1)
                }.frame(maxWidth: .infinity)
                VStack(spacing: 3) {
                    VStack(spacing: 0) { Text(verbatim: String(info.month)); Text("月") }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    caption(reading.japaneseMonthName, size: 9)
                    Spacer(minLength: 3)
                    metric(info.report.dayPillar.label, reading.tradition.dayAnimal)
                    Text(verbatim: reading.guardianMark).font(.system(size: 9, weight: .bold, design: .serif))
                        .frame(width: 15, height: 15).overlay { Circle().strokeBorder(lineWidth: 0.6) }
                        .accessibilityHidden(true)
                    metric(String(reading.tradition.mansion.prefix(1)), reading.tradition.mansionEnglish)
                }.frame(width: 48)
            }.frame(height: 142).padding(.top, 2)
            HStack(spacing: 3) {
                dial("DAY BRANCH", .branch, reading.tradition.dayAnimal)
                dial("EARTH · MOON", .geometry, "日 · 地 · 月")
                dial("PLANET ORBITS", .planets, "HELIOCENTRIC")
                dial("MOON PHASE", .moon, reading.moonCaption)
                dial("SUN SIGN", .zodiac, reading.sign)
            }.padding(.top, 12)
            VStack(alignment: .leading, spacing: 4) {
                caption("ON THIS DATE", size: 6.3).tracking(0.9)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    caption(String(reading.history.year), size: 9)
                    Text(verbatim: reading.history.text)
                        .font(.system(size: 8.4, weight: .medium)).fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if widget {
                    if let credit = reading.launchCredit { caption(credit, size: 5.9) }
                } else {
                    Link(destination: reading.history.sourceURL) {
                        caption((reading.launchCredit ?? "HISTORICAL SOURCE") + "  ↗", size: 5.9)
                    }.buttonStyle(.plain)
                }
            }.padding(.top, 12)
            Spacer(minLength: 5)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    caption("旧暦 +09  " + reading.japaneseDate + "   農曆 +08  " + info.lunarCaption, size: 7)
                    caption(reading.tradition.guardian.uppercased(), size: 6.6)
                    let term = info.report.termOnDate ?? info.report.nextTerm
                    caption(termName(term) + "  " + term.date.label.suffix(5), size: 7)
                    caption("TOKYO DAYLIGHT   " + reading.daylight, size: 6.6)
                }
                Spacer()
                VStack(spacing: 2) { caption(String(format: "WEEK %02d", reading.week), size: 5.6); monthIndex }
            }
        }
        .padding(.horizontal, 12).padding(.top, 30).padding(.bottom, 8)
        .foregroundStyle(Self.black)
        .background { Self.paper; PaperGrain(seed: info.dayOfYear, strength: 0.8) }
    }

    private func starSeal(_ star: Int) -> some View {
        Canvas { context, size in
            let pitch = size.width / 3
            for i in 0..<9 {
                let x = CGFloat(i % 3) * pitch + pitch / 2
                let y = CGFloat(i / 3) * pitch + pitch / 2
                let circle = Path(ellipseIn: CGRect(x: x - 1.4, y: y - 1.4, width: 2.8, height: 2.8))
                if i < star {
                    context.fill(circle, with: .foreground)
                } else {
                    context.stroke(circle, with: .foreground, lineWidth: 0.5)
                }
            }
        }.frame(width: 13, height: 13).accessibilityHidden(true)
    }
    private func caption(_ s: String, size: CGFloat) -> some View {
        Text(verbatim: s).font(.system(size: size, weight: .semibold, design: .monospaced))
    }
    private func vertical(_ s: String) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(s.enumerated()), id: \.offset) { _, c in Text(verbatim: String(c)) }
        }.font(.system(size: 16, weight: .bold, design: .rounded)).fixedSize()
    }
    private func metric(_ value: String, _ legend: String) -> some View {
        VStack(spacing: 0) {
            Text(verbatim: value).font(.system(size: 10, weight: .bold))
            caption(legend.uppercased(), size: 5.8).lineLimit(2).multilineTextAlignment(.center)
        }.padding(.top, 3)
    }
    private func dial(_ label: String, _ kind: CelestialDial.Kind, _ value: String) -> some View {
        VStack(spacing: 3) {
            caption(label, size: 6).lineLimit(1).minimumScaleFactor(0.75)
            CelestialDial(kind: kind, reading: reading).frame(width: 38, height: 38)
            caption(value.uppercased(), size: 5.9).lineLimit(1).minimumScaleFactor(0.75)
        }.frame(maxWidth: .infinity)
    }
    private var monthIndex: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array("SMTWTFS".enumerated()), id: \.offset) { col, c in
                    caption(String(c), size: 4.6).frame(width: 7.5, height: 6)
                        .foregroundStyle(Self.ink(weekday: col + 1))
                }
            }
            ForEach(Array(info.grid.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { col, day in
                        Text(verbatim: day.map(String.init) ?? "")
                            .font(.system(size: 4.6, weight: .medium, design: .monospaced))
                            .foregroundStyle(day == info.day ? Self.paper : Self.ink(weekday: col + 1))
                            .frame(width: 7.5, height: 7)
                            .background { if day == info.day { Circle().fill(ink) } }
                    }
                }
            }
        }.accessibilityHidden(true)
    }
}
