import CoreText
import SwiftUI

struct KoreanProverb {
    let korean: String
    let english: String

    private final class ResourceBundle {}
    static let entries: [Self] = {
        guard let url = Bundle(for: ResourceBundle.self).url(forResource: "KoreanProverbs", withExtension: "tsv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.split(whereSeparator: \.isNewline).compactMap { line in
            guard !line.hasPrefix("#") else { return nil }
            let fields = line.split(separator: "\t")
            guard fields.count == 2 else { return nil }
            return Self(korean: String(fields[0]), english: String(fields[1]))
        }
    }()

    static func on(_ id: Int64) -> Self {
        guard !entries.isEmpty else { return Self(korean: "말이 씨가 된다", english: "Words become seeds.") }
        let count = Int64(entries.count)
        return entries[Int((id % count + count) % count)]
    }
}

struct IllyeokReading {
    let info: DayInfo
    let proverb: KoreanProverb
    let lunar: String
    private static let lunarFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR@calendar=dangi")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "MMM d'일'"
        return formatter
    }()

    init(_ page: PrintedDay) {
        info = DayInfo(page: page)
        proverb = .on(page.date.dayID.value)
        // Interpret the displayed civil date at noon in Korea, wherever the pad lives.
        let noon = Date(timeIntervalSince1970: Double(page.date.dayID.value * 86_400 + 3 * 3_600))
        lunar = Self.lunarFormatter.string(from: noon)
    }

    var newYear: Bool { info.month == 1 && info.day == 1 }
    var ink: Color {
        if newYear || info.isSunday { return IllyeokFace.red }
        return info.isSaturday ? IllyeokFace.blue : IllyeokFace.black
    }
    var weekday: String { ["일", "월", "화", "수", "목", "금", "토"][info.weekday - 1] + "요일" }
    var dateLine: String {
        let pillar = info.report.dayPillar.label
        return "음력  " + lunar + "   ·   " + pillar + (newYear ? "   신정" : "")
    }
    var summary: String {
        [info.page.date.label, weekday, dateLine, proverb.korean, proverb.english].joined(separator: ". ")
    }
}

struct IllyeokBinding: View {
    var body: some View {
        GeometryReader { box in
            let h = box.size.height
            ZStack {
                Color(red: 0.73, green: 0.85, blue: 0.76)
                IllyeokPattern().foregroundStyle(.white.opacity(0.32))
                HStack {
                    Circle().fill(.white.opacity(0.85))
                    Spacer()
                    Circle().fill(.white.opacity(0.85))
                }
                .frame(height: h * 0.24).padding(.horizontal, box.size.width * 0.18)
            }
        }
    }
}

// A continuous four-petal print shared by the binding and the numerals.
private struct IllyeokPattern: View {
    var body: some View {
        Canvas { context, size in
            var paths = Path()
            for row in 0...Int(size.height / 8) {
                for col in 0...Int(size.width / 8) {
                    let x = CGFloat(col * 8) + (row.isMultiple(of: 2) ? 0 : 4)
                    let y = CGFloat(row * 8)
                    for (dx, dy) in [(0.0, -1.6), (1.6, 0), (0, 1.6), (-1.6, 0)] {
                        paths.addEllipse(in: CGRect(x: x + dx - 1.45, y: y + dy - 1.45, width: 2.9, height: 2.9))
                    }
                }
            }
            context.stroke(paths, with: .foreground, lineWidth: 0.55)
        }
    }
}

struct IllyeokNumeral: View {
    let day: Int
    let ink: Color
    var roundel = false

    private final class FontBundle {}

    private static let numeralFont: CTFont = {
        guard let url = Bundle(for: FontBundle.self).url(forResource: "BesleyNarrow-ExtraBold", withExtension: "otf"),
              let provider = CGDataProvider(url: url as CFURL),
              let face = CGFont(provider) else {
            assertionFailure("Missing bundled Besley Narrow ExtraBold")
            return CTFontCreateUIFontForLanguage(.emphasizedSystem, 100, nil)!
        }
        return CTFontCreateWithGraphicsFont(face, 100, nil, nil)
    }()

    private static let figures: [Path] = {
        // Use a common 100-unit cap height. The three figures visible in the
        // reference have distinctive outlines, especially the parallel sides of 0.
        let widths: [CGFloat] = [49, 49, 59, 58, 65, 62, 60, 58, 59, 60]
        return (0...9).map { digit in
            switch digit {
            case 0:
                var zero = Path()
                zero.addRoundedRect(in: CGRect(x: 0, y: 0, width: 49, height: 100),
                                    cornerSize: CGSize(width: 24.5, height: 27))
                var slot = Path()
                slot.addRoundedRect(in: CGRect(x: 18.5, y: 8.5, width: 12, height: 83),
                                    cornerSize: CGSize(width: 6, height: 8))
                return zero.subtracting(slot)
            case 1:
                var one = Path()
                one.move(to: CGPoint(x: 1, y: 12))
                one.addQuadCurve(to: CGPoint(x: 21, y: 0), control: CGPoint(x: 15, y: 9))
                one.addLine(to: CGPoint(x: 34, y: 0))
                one.addLine(to: CGPoint(x: 34, y: 92))
                one.addLine(to: CGPoint(x: 49, y: 92))
                one.addLine(to: CGPoint(x: 49, y: 100))
                one.addLine(to: CGPoint(x: 0, y: 100))
                one.addLine(to: CGPoint(x: 0, y: 92))
                one.addLine(to: CGPoint(x: 14.5, y: 92))
                one.addLine(to: CGPoint(x: 14.5, y: 18))
                one.addLine(to: CGPoint(x: 1, y: 18))
                one.closeSubpath()
                return one
            case 5:
                var five = Path()
                five.move(to: CGPoint(x: 2, y: 1))
                five.addLine(to: CGPoint(x: 62, y: 0))
                five.addCurve(to: CGPoint(x: 47, y: 18), control1: CGPoint(x: 56, y: 3), control2: CGPoint(x: 60, y: 18))
                five.addLine(to: CGPoint(x: 10, y: 18))
                five.addLine(to: CGPoint(x: 10, y: 41))
                five.addCurve(to: CGPoint(x: 62, y: 61), control1: CGPoint(x: 33, y: 25), control2: CGPoint(x: 59, y: 33))
                five.addCurve(to: CGPoint(x: 33, y: 100), control1: CGPoint(x: 66, y: 83), control2: CGPoint(x: 50, y: 100))
                five.addCurve(to: CGPoint(x: 0, y: 77), control1: CGPoint(x: 16, y: 101), control2: CGPoint(x: 1, y: 92))
                five.addCurve(to: CGPoint(x: 11, y: 63), control1: CGPoint(x: -1, y: 69), control2: CGPoint(x: 4, y: 63))
                five.addCurve(to: CGPoint(x: 12, y: 84), control1: CGPoint(x: 24, y: 62), control2: CGPoint(x: 27, y: 82))
                five.addQuadCurve(to: CGPoint(x: 28, y: 92), control: CGPoint(x: 17, y: 92))
                five.addCurve(to: CGPoint(x: 43, y: 66), control1: CGPoint(x: 39, y: 92), control2: CGPoint(x: 45, y: 78))
                five.addCurve(to: CGPoint(x: 23, y: 44), control1: CGPoint(x: 42, y: 51), control2: CGPoint(x: 34, y: 43))
                five.addQuadCurve(to: CGPoint(x: 1, y: 54), control: CGPoint(x: 10, y: 44))
                five.closeSubpath()
                return five
            default:
                var code = UniChar(48 + digit), glyph = CGGlyph()
                CTFontGetGlyphsForCharacters(numeralFont, &code, &glyph, 1)
                guard let outline = CTFontCreatePathForGlyph(numeralFont, glyph, nil) else { return Path() }
                let bounds = outline.boundingBoxOfPath
                let x = widths[digit] / bounds.width, y = 100 / bounds.height
                return Path(outline).applying(CGAffineTransform(a: x, b: 0, c: 0, d: -y,
                                                               tx: -bounds.minX * x, ty: bounds.maxY * y))
            }
        }
    }()

    // Measured between ink bounds at a 100-unit cap height. Sloping strokes
    // and the inset stem of 1 leave extra white space inside those bounds.
    private var pairGap: CGFloat {
        switch day {
        case 14, 17, 24, 27: return 3
        case 11, 21, 31: return 4
        case 12, 13, 16, 19, 23, 26, 29, 30: return 5.5
        default: return 7.5
        }
    }

    var body: some View {
        GeometryReader { box in
            let h = box.size.height
            let w = box.size.width
            let digits = String(day).compactMap(\.wholeNumberValue)
            var outline: Path {
                var p = Path()
                for digit in digits {
                    let start = p.isEmpty ? 0 : p.boundingRect.maxX + pairGap
                    p.addPath(Self.figures[digit], transform: CGAffineTransform(translationX: start, y: 0))
                }
                let width = min(w * 0.88, p.boundingRect.width * h / 100)
                return p.applying(CGAffineTransform(a: width / p.boundingRect.width, b: 0, c: 0, d: h / 100,
                                                    tx: (w - width) / 2, ty: 0))
            }
            let shape = outline
            ZStack {
                if roundel {
                    Canvas { ctx, size in
                        let d = min(size.height * 0.78, size.width * 0.85)
                        let rect = CGRect(x: (size.width - d) / 2, y: (size.height - d) / 2, width: d, height: d)
                        ctx.translateBy(x: rect.minX, y: rect.minY)
                        ctx.scaleBy(x: d / 100, y: d / 100)
                        let ring = Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 100))
                        ctx.stroke(ring, with: .color(ink), lineWidth: 0.85)
                        ctx.clip(to: ring)
                        var top = Path()
                        top.move(to: CGPoint(x: 0, y: 50))
                        top.addCurve(to: CGPoint(x: 50, y: 50), control1: CGPoint(x: 0, y: 84), control2: CGPoint(x: 50, y: 84))
                        top.addCurve(to: CGPoint(x: 100, y: 50), control1: CGPoint(x: 50, y: 16), control2: CGPoint(x: 100, y: 16))
                        top.addLine(to: CGPoint(x: 100, y: 0))
                        top.addLine(to: .zero)
                        top.closeSubpath()
                        ctx.clip(to: top)
                        var hatch = Path()
                        for y in stride(from: 0, to: 100, by: 1.35) {
                            hatch.move(to: CGPoint(x: 0, y: y))
                            hatch.addLine(to: CGPoint(x: 100, y: y))
                        }
                        ctx.stroke(hatch, with: .color(ink.opacity(0.72)), lineWidth: 0.55)
                    }
                }
                shape.fill(Color(white: 0.91)).offset(x: h * 0.026, y: h * 0.015)
                shape.fill(ink)
                IllyeokPattern().foregroundStyle(.white.opacity(0.18)).mask(shape.fill(.black))
            }
        }.dayNumberTarget()
    }
}

struct IllyeokFace: View {
    let reading: IllyeokReading
    var widget = false
    static let paper = Color(red: 0.993, green: 0.990, blue: 0.979)
    static let black = Color(red: 0.13, green: 0.125, blue: 0.12)
    static let blue = Color(red: 0.12, green: 0.30, blue: 0.59)
    static let red = Color(red: 0.71, green: 0.17, blue: 0.115)
    private var info: DayInfo { reading.info }

    var body: some View {
        GeometryReader { box in
            let w = box.size.width, h = box.size.height
            let wide = w > h * 1.5
            let compact = widget && h < 220 && !wide
            let u = wide ? min(w / 330, h / 155) : min(w / 300, h / 400)
            VStack(spacing: 0) {
                if widget && !compact {
                    IllyeokBinding().frame(height: (wide ? 14 : 19) * u)
                } else if !widget {
                    Color.clear.frame(height: 28 * u)
                }
                if wide {
                    HStack(spacing: 15 * u) {
                        VStack(spacing: 7 * u) {
                            Text(verbatim: "\(info.month)월  ·  " + reading.weekday)
                                .font(.system(size: 12 * u, weight: .bold))
                            numeral
                        }.frame(width: w * 0.35)
                        VStack(alignment: .leading, spacing: 6 * u) {
                            Text(verbatim: reading.dateLine).font(.system(size: 10 * u, weight: .semibold))
                            proverb(korean: 16 * u, english: 12 * u)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(12 * u)
                } else if compact {
                    VStack(spacing: 4) {
                        Text(verbatim: "\(info.month)월  ·  " + reading.weekday)
                            .font(.system(size: 11, weight: .bold))
                        numeral
                        proverb(korean: 12, english: 10)
                    }.padding(.horizontal, 10).padding(.vertical, 7)
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            stamp(String(info.month), String(monthNamesEN[info.month].prefix(3)), u)
                            Spacer(minLength: 2 * u)
                            miniMonth(u)
                            Spacer(minLength: 2 * u)
                            stamp(String(info.weekdayKanji.prefix(1)), info.weekdayEN, u)
                        }
                        Text(verbatim: reading.dateLine)
                            .font(.system(size: 13 * u, weight: .bold)).padding(.vertical, 9 * u)
                        numeral
                        proverb(korean: 15 * u, english: 12 * u)
                            .frame(maxWidth: .infinity, minHeight: 64 * u, alignment: .leading)
                            .padding(.top, 8 * u)
                    }.padding(.horizontal, 17 * u).padding(.vertical, 10 * u)
                }
            }
            .frame(width: w, height: h)
            .foregroundStyle(reading.ink)
            .background(Self.paper)
        }.accessibilityElement(children: .ignore).accessibilityLabel(reading.summary)
    }

    private var numeral: some View {
        IllyeokNumeral(day: info.day, ink: reading.ink, roundel: reading.newYear)
    }

    private func stamp(_ value: String, _ caption: String, _ u: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(verbatim: value).font(.custom("Georgia-Bold", fixedSize: 26 * u))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(verbatim: caption.uppercased()).font(.system(size: 8 * u, weight: .black))
                .tracking(2.2 * u).frame(maxWidth: .infinity).padding(.vertical, u)
                .foregroundStyle(Self.paper).background(reading.ink)
        }
        .frame(width: 56 * u, height: 39 * u)
        .clipShape(RoundedRectangle(cornerRadius: 2 * u))
        .overlay(RoundedRectangle(cornerRadius: 2 * u).strokeBorder(reading.ink, lineWidth: 1.5 * u))
    }

    private func miniMonth(_ u: CGFloat) -> some View {
        VStack(spacing: u) {
            Text(verbatim: "\(info.year)   ·   \(info.month)월")
                .font(.system(size: 7.5 * u, weight: .bold, design: .serif))
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array("일월화수목금토"), id: \.self) { letter in
                        Text(verbatim: String(letter)).font(.system(size: 5.5 * u, weight: .bold))
                    }
                }
                let weeks = info.grid
                ForEach(weeks.indices, id: \.self) { row in
                    GridRow {
                        ForEach(0..<7, id: \.self) { col in
                            let day = weeks[row][col]
                            Text(verbatim: day.map(String.init) ?? " ")
                                .font(.system(size: 6.3 * u, weight: .bold, design: .serif))
                                .frame(width: 13 * u, height: 7 * u)
                                .foregroundStyle(day == info.day ? Self.paper : reading.ink)
                                .background { if day == info.day { Capsule().fill(reading.ink) } }
                        }
                    }
                }
            }.padding(2 * u).border(reading.ink, width: 0.6 * u)
        }
    }

    private func proverb(korean: CGFloat, english: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: korean * 0.22) {
            Text(verbatim: reading.proverb.korean)
                .font(.system(size: korean, weight: .semibold))
            Text(verbatim: reading.proverb.english)
                .font(.custom("Georgia", fixedSize: english))
        }.foregroundStyle(Self.black)
            .fixedSize(horizontal: false, vertical: true)
    }
}
