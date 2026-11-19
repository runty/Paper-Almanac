import SwiftUI
import TungShingData

// The bound sheet is 400 × 500 print points. Widgets can widen the plate at the same type size.
struct PrintFace: View {
    let day: PrintedDay
    var plateWidth: CGFloat = 400
    var showsPageBorder = true
    static let green = Color(red: 0.025, green: 0.32, blue: 0.22)
    private static let red = Color(red: 0.86, green: 0.10, blue: 0.27)
    private let stock = Color(red: 1, green: 0.994, blue: 0.98)
    static func dateInk(for day: PrintedDay) -> Color {
        day.holiday != nil || [0, 6].contains(day.date.weekdaySunday0) ? red : green
    }
    private var rule: Color { Self.dateInk(for: day) }
    private var ink: Color { day.holiday == nil ? rule : Self.green }
    private let months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    private let numbers = ["一","二","三","四","五","六","七","八","九","十","十一","十二"]
    private let ordinals = ["First","Second","Third","Fourth","Fifth","Sixth","Seventh","Eighth","Ninth","Tenth","Eleventh","Twelfth"]
    private let weekdays = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    private let termNames = ["Spring equinox","Clear and bright","Grain rain","Start of summer","Grain full","Grain in ear","Summer solstice","Minor heat","Major heat","Start of autumn","End of heat","White dew","Autumn equinox","Cold dew","Frost falls","Start of winter","Light snow","Heavy snow","Winter solstice","Minor cold","Major cold","Start of spring","Rain water","Awakening insects"]

    private func label(_ value: String, _ size: CGFloat) -> some View {
        Text(verbatim: value.uppercased()).font(.custom("HelveticaNeue-Bold", size: size))
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        let month = Int(day.date.month) - 1, weekday = Int(day.date.weekdaySunday0)
        let report = day.report, term = report.termOnDate ?? report.nextTerm
        let termIndex = Int(term.indexFromMarchEquinox)
        let lunarMonth = (report.lunar.isLeapMonth ? "Leap " : "") + ordinals[Int(report.lunar.month)-1] + " month"
        let holiday = day.holiday
        ZStack {
            stock
            PaperGrain(seed: Int(day.date.month) * 32 + Int(day.date.day), strength: 1.3)
            if showsPageBorder { Rectangle().strokeBorder(rule, lineWidth: 1.6) }
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    label(String(day.date.year), 19).frame(width: 78, alignment: .leading)
                    label(months[month], 21).tracking(0.7).frame(maxWidth: .infinity)
                    label(numbers[month] + "月", 18).frame(width: 78, alignment: .trailing)
                }.padding(.horizontal, 8).frame(height: 37).foregroundStyle(rule)
                Rectangle().fill(rule).frame(height: 0.7)
                Rectangle().fill(rule).frame(height: 1.7).padding(.top, 1.8)
                Color.clear.overlay {
                    TungShingNumeral(day: Int(day.date.day), size: 207)
                        .foregroundStyle(rule)
                        .dayNumberTarget().accessibilityHidden(true)
                }.overlay {
                    HStack {
                        rail(report.termOnDate == nil ? "Next\nsolar term" : "Solar term\ntoday",
                             detail: String(format: "%02d.%02d", term.date.month, term.date.day),
                             vertical: termNames[termIndex], foot: Calendar2100Provider.termNames[termIndex], angle: -90)
                        Spacer()
                        rail("Lunar\ndate", detail: "―", vertical: lunarMonth, foot: String(report.lunar.day), angle: 90)
                    }
                }.frame(maxHeight: .infinity)
                if let holiday {
                    HStack {
                        label(holiday.chinese, 24)
                        Spacer()
                        label(holiday.english, 16)
                    }.padding(.horizontal, 14).frame(height: 35)
                        .overlay { Rectangle().strokeBorder(rule, lineWidth: 1) }.padding(.bottom, 7)
                }
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        label(weekdays[weekday], 18).frame(maxWidth: .infinity)
                        label("星期" + ["日","一","二","三","四","五","六"][weekday], 19)
                            .frame(maxWidth: .infinity, maxHeight: .infinity).background(ink).foregroundStyle(stock)
                    }.frame(height: 32)
                    Rectangle().fill(rule).frame(height: 1)
                    if holiday == nil {
                        hourStrip
                        Rectangle().fill(rule).frame(height: 1)
                    }
                    HStack(spacing: 0) {
                        column("宜", "Do", side: .recommended, reading: day.recommended)
                        Rectangle().fill(rule).frame(width: 1)
                        column("忌", "Avoid", side: .avoided, reading: day.avoided)
                    }.frame(height: 129)
                    Rectangle().fill(rule).frame(height: 1)
                    HStack {
                        label("Day pillar   日柱  " + report.dayPillar.label, 10)
                        Spacer()
                        label("Lunar date   " + report.lunarMonthLabel + report.lunarDayLabel, 10)
                    }.padding(.horizontal, 10).frame(height: 19)
                    if let proverb = ChineseProverb.on(day.date) {
                        Rectangle().fill(rule).frame(height: 1)
                        ProverbStrip(proverb: proverb, ink: ink, paper: stock)
                            .frame(height: 27)
                    }
                }.clipShape(panelShape).overlay { panelShape.strokeBorder(rule, lineWidth: 1.1) }
            }.padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 12)
        }.frame(width: plateWidth, height: 500).foregroundStyle(ink)
    }

    private var hourStrip: some View {
        VStack(spacing: 3) {
            label("Hours  ·  吉 Favourable   凶 Unfavourable", 8.5)
            HStack(spacing: 0) {
                // First and last Zi segments belong to opposite ends of this civil day.
                ForEach(Array(day.report.hourLuckIsInauspicious.enumerated()), id: \.offset) { index, avoided in
                    VStack(spacing: 1) {
                        label(String(format: "%02d", max(0, 2 * index - 1)), 8.5)
                        label(avoided ? "凶" : "吉", 11)
                    }.frame(maxWidth: .infinity)
                }
            }
        }.padding(.horizontal, 4).frame(height: 41)
    }

    private var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 15, bottomTrailingRadius: 15)
    }

    private func rail(_ title: String, detail: String, vertical: String, foot: String, angle: Double) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                label(title, 9.5)
                label(detail, 9)
            }.frame(height: 40, alignment: .top)
            Spacer()
            label(vertical, 16).frame(width: 96).rotationEffect(.degrees(angle)).frame(width: 44, height: 96)
            Spacer()
            label(foot, 17)
        }.frame(width: 69).padding(.vertical, 10)
    }

    private func column(_ chinese: String, _ english: String, side: ActivityPreference.Side, reading: Reading) -> some View {
        HStack(spacing: 0) {
            if chinese == "宜" { seal(chinese, english) }
            VStack(spacing: 4) {
                ForEach(reading.lines, id: \.self) { text in label(text, 11) }
                if reading.remaining > 0 {
                    label("+\(reading.remaining) more", 8)
                }
            }.padding(.horizontal, 4).frame(maxWidth: .infinity)
            if chinese == "忌" { seal(chinese, english) }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .activityLink(day: day.date.label, side: side)
    }

    private func seal(_ chinese: String, _ english: String) -> some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                var rays = Path()
                for i in 0..<84 {
                    let angle = Double(i) * .pi / 42
                    rays.move(to: center)
                    rays.addLine(to: CGPoint(x: center.x + cos(angle) * 80, y: center.y + sin(angle) * 80))
                }
                context.stroke(rays, with: .color(rule), lineWidth: 0.9)
            }
            VStack(spacing: 0) { label(chinese, 23); label(english, 9) }
                .foregroundStyle(stock).frame(width: 44, height: 44)
                .background(Circle().fill(ink))
                .padding(2).background(Circle().fill(stock))
                .overlay { Circle().stroke(rule, lineWidth: 0.9) }
        }.frame(width: 54).clipped().border(rule, width: 0.65)
    }
}

struct ProverbStrip: View {
    let proverb: ChineseProverb
    let ink: Color
    let paper: Color
    var compact = false

    var body: some View {
        HStack(spacing: 0) {
            Text(verbatim: "CHINESE\nPROVERB")
                .font(.custom("HelveticaNeue-Bold", size: compact ? 7.5 : 9.5))
                .tracking(0.3)
                .fixedSize()
                .frame(width: compact ? 45 : 62)
                .frame(maxHeight: .infinity)
                .foregroundStyle(paper).background(ink)
            Text(verbatim: proverb.english.uppercased())
                .font(.custom("HelveticaNeue-Bold", size: compact ? 8.5 : 9.5))
                .lineLimit(compact ? nil : 2).minimumScaleFactor(0.9)
                .padding(.horizontal, compact ? 3 : 9)
                .frame(maxWidth: .infinity)
                .foregroundStyle(ink)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Chinese proverb. " + proverb.english))
    }
}
