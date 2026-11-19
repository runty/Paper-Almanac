import SwiftUI
import TungShingDailyAlmanac

/// The National Diet Library's two sets of day branches, in solar-month order from Risshun.
enum Kinun {
    static let paperRGB = SIMD3<Float>(0.995, 0.845, 0.385)
    static let paper = Color(red: Double(paperRGB.x), green: Double(paperRGB.y), blue: Double(paperRGB.z))
    static let board = Color(red: 0.974, green: 0.746, blue: 0.105)
    static let gold = Color(red: 0.54, green: 0.35, blue: 0.073)
    static let seal = Color(red: 0.68, green: 0.18, blue: 0.075)
    static let boardWidth = Metrics.pageW + 16
    static let headerHeight: CGFloat = 44
    static let grainDay = "一粒万倍日"
    private static let branches = ["丑午", "酉寅", "子卯", "卯辰", "巳午", "酉午", "子未", "卯申", "酉午", "酉戌", "亥子", "卯子"]

    static func isGrainDay(_ day: PrintedDay) -> Bool {
        guard let season = JapaneseSeason(on: day.date) else { return false }
        return branches[(season.number - 1) / 6].contains(day.report.dayPillar.branch)
    }

    static func summary(_ reading: NihonReading) -> String {
        reading.summary + (isGrainDay(reading.info.page) ? ". 一粒万倍日. One grain, ten thousandfold." : "")
    }
}

/// An eight-sided gilt mirror with a square coin opening and eight printed trigrams.
private struct GiltMirror: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 100, y: size.height / 100)
            ctx.translateBy(x: 50, y: 50)
            let foil = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Kinun.gold, Color(red: 1, green: 0.92, blue: 0.56), Kinun.gold]),
                startPoint: .init(x: -32, y: -38), endPoint: .init(x: 29, y: 34))
            func octagon(_ radius: CGFloat) -> Path {
                Path { path in
                    for i in 0..<8 {
                        let angle = (Double(i) + 0.5) * .pi / 4
                        let p = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                    path.closeSubpath()
                }
            }
            ctx.stroke(octagon(50), with: foil, lineWidth: 2)
            ctx.stroke(octagon(47), with: .color(Kinun.gold), lineWidth: 0.7)
            ctx.fill(octagon(27), with: foil)
            ctx.fill(Path(CGRect(x: -5, y: -5, width: 10, height: 10)), with: .color(Kinun.board))
            for mask in [7, 3, 5, 1, 0, 4, 2, 6] {
                for i in 0..<3 {
                    let y = -31 - i * 4
                    if mask & (1 << i) != 0 {
                        ctx.fill(Path(CGRect(x: -10, y: y, width: 20, height: 2)), with: foil)
                    } else {
                        for x in [-10, 2] {
                            ctx.fill(Path(CGRect(x: x, y: y, width: 8, height: 2)), with: foil)
                        }
                    }
                }
                ctx.rotate(by: .degrees(45))
            }
        }
    }
}

struct KinunBoard: View {
    var body: some View {
        ZStack(alignment: .top) {
            Kinun.board
            PaperGrain(seed: 88, strength: 0.85)
            GiltMirror()
                .frame(width: 32, height: 32)
                .frame(height: Kinun.headerHeight)
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .accessibilityHidden(true)
    }
}

/// A tied gourd and a bowed ear of rice, printed beside the lucky-day inscription.
struct KinunHarvestMark: Shape {
    func path(in rect: CGRect) -> Path {
        var mark = Path()
        // The gourd has a small upper chamber, pinched waist and plump base.
        mark.move(to: CGPoint(x: 10, y: 1))
        mark.addQuadCurve(to: CGPoint(x: 9, y: 3), control: CGPoint(x: 8.7, y: 1.5))
        mark.addCurve(to: CGPoint(x: 6.4, y: 8), control1: CGPoint(x: 5.4, y: 2.2), control2: CGPoint(x: 4.8, y: 5.8))
        mark.addCurve(to: CGPoint(x: 2, y: 12), control1: CGPoint(x: 5, y: 8.7), control2: CGPoint(x: 2.6, y: 9))
        mark.addCurve(to: CGPoint(x: 10.8, y: 15), control1: CGPoint(x: 0.4, y: 17.8), control2: CGPoint(x: 8.9, y: 20))
        mark.addQuadCurve(to: CGPoint(x: 9.6, y: 9), control: CGPoint(x: 12.4, y: 11.7))
        mark.addCurve(to: CGPoint(x: 9, y: 3), control1: CGPoint(x: 14.2, y: 7.5), control2: CGPoint(x: 14.2, y: 3.8))
        mark.move(to: CGPoint(x: 6.2, y: 8))
        mark.addQuadCurve(to: CGPoint(x: 11, y: 9.2), control: CGPoint(x: 8.3, y: 9.4))
        mark.addQuadCurve(to: CGPoint(x: 16, y: 14), control: CGPoint(x: 14.8, y: 8.4))

        // Narrow, pointed grains hang from alternating sides of the stalk.
        mark.move(to: CGPoint(x: 16, y: 17))
        mark.addQuadCurve(to: CGPoint(x: 36, y: 6), control: CGPoint(x: 23, y: -1))
        for (x, y) in [(22.0, 8.1), (25.7, 6.1), (29.7, 5.3), (33.2, 5.5)] {
            let joint = CGPoint(x: x, y: y)
            for tip in [CGPoint(x: x - 1, y: y + 5.4), CGPoint(x: x + 1.5, y: y - 3.6)] {
                mark.move(to: joint)
                mark.addQuadCurve(to: tip, control: CGPoint(x: x - 1.35, y: (y + tip.y) / 2))
                mark.addQuadCurve(to: joint, control: CGPoint(x: x + 2.2, y: (y + tip.y) / 2))
            }
        }
        return mark.applying(CGAffineTransform(scaleX: rect.width / 37, y: rect.height / 19))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}
