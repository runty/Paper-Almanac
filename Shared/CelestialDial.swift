import SwiftUI
import TungShingDailyAlmanac

/// Angles are plotted anticlockwise. Rings show orbital order, not distance.
struct CelestialDial: View {
    enum Kind { case branch, geometry, planets, moon, zodiac }
    let kind: Kind
    let reading: CelestialReading

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 40, y: size.height / 40)
            let center = CGPoint(x: 20, y: 20)
            let black = CelestialFace.black
            func point(_ center: CGPoint, _ radius: CGFloat, _ degrees: Double) -> CGPoint {
                let a = degrees * .pi / 180
                return CGPoint(x: center.x + radius * cos(a), y: center.y - radius * sin(a))
            }
            func disc(_ center: CGPoint, _ radius: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: 2*radius, height: 2*radius))
            }
            func dot(_ center: CGPoint, _ radius: CGFloat, _ ink: Color) {
                ctx.fill(disc(center, radius), with: .color(ink))
            }
            func orbit(_ center: CGPoint, _ radius: CGFloat, _ weight: CGFloat = 0.4) {
                ctx.stroke(disc(center, radius), with: .color(black), lineWidth: weight)
            }
            func glyph(_ value: String, _ font: Font) {
                ctx.draw(Text(verbatim: value).font(font).foregroundStyle(black), at: center)
            }

            orbit(center, 19, 0.65)
            if kind == .branch {
                let branch = Int(reading.info.report.dayPillar.branchIndex)
                for i in 0..<12 {
                    dot(point(center, 15.8, 90 - Double(i)*30), i == branch ? 1.7 : 0.65, black)
                }
                glyph(String(reading.info.report.dayPillar.label.suffix(1)), .system(size: 17, weight: .heavy, design: .serif))
                return
            }
            guard let sky = reading.sky else { return }
            switch kind {
            case .branch: break
            case .geometry:
                orbit(center, 12)
                let earthAngle = sky.planetLongitudes[2]
                let earth = point(center, 12, earthAngle)
                orbit(earth, 5)
                dot(earth, 1.85, CelestialFace.blue)
                let phaseAngle = sky.moonAgeDays / CelestialSky.meanSynodicMonthDays * 360
                dot(point(earth, 5, earthAngle + 180 + phaseAngle), 1.15, black)
                for i in 0..<24 {
                    var ray = Path()
                    ray.move(to: point(center, 3.6, Double(i)*15))
                    ray.addLine(to: point(center, 6.3, Double(i)*15))
                    ctx.stroke(ray, with: .color(CelestialFace.red.opacity(0.75)), lineWidth: 0.4)
                }
                dot(center, 3, CelestialFace.red)
            case .planets:
                for (i, longitude) in sky.planetLongitudes.enumerated() {
                    let radius = 3.1 + CGFloat(i)*2.05
                    orbit(center, radius)
                    dot(point(center, radius, longitude), i == 2 ? 1.5 : 0.95, i == 2 ? CelestialFace.blue : black)
                }
                dot(center, 1.6, CelestialFace.red)
            case .moon:
                MoonDisc.draw(in: &ctx, sky: sky, ink: black, paper: CelestialFace.paper)
            case .zodiac:
                for i in 0..<12 {
                    var tick = Path()
                    let a = Double(i) * 30
                    tick.move(to: point(center, 16, a)); tick.addLine(to: point(center, 18.6, a))
                    ctx.stroke(tick, with: .color(black), lineWidth: 0.55)
                }
                dot(point(center, 15.5, sky.sunLongitude), 1.7, CelestialFace.red)
                glyph(String(CelestialReading.glyphs[sky.sunSignIndex]) + "\u{FE0E}", .system(size: 19, weight: .regular))
            }
        }
    }
}

struct MoonDisc: View {
    let sky: CelestialSky
    let ink: Color
    let paper: Color
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 40, y: size.height / 40)
            Self.draw(in: &context, sky: sky, ink: ink, paper: paper)
            context.stroke(Path(ellipseIn: CGRect(x: 1.4, y: 1.4, width: 37.2, height: 37.2)),
                           with: .color(ink), lineWidth: 1)
        }
    }
    static func draw(in ctx: inout GraphicsContext, sky: CelestialSky, ink: Color, paper: Color) {
        let radius: CGFloat = 18.6
        let phase = sky.moonIllumination
        // Trace the illuminated limb and elliptical terminator, viewed north-up.
        ctx.fill(Path(ellipseIn: CGRect(x: 20-radius, y: 20-radius, width: 2*radius, height: 2*radius)), with: .color(ink))
        let bounds = CGRect(x: 20-radius, y: 20-radius, width: 2*radius, height: 2*radius)
        let light = IlluminatedLimb(fraction: phase, waxing: sky.moonIsWaxing).path(in: bounds)
        ctx.fill(light, with: .color(paper))
    }
}

/// Project the terminator onto a north-up circular disk.
struct IlluminatedLimb: Shape {
    let fraction: Double
    let waxing: Bool
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        var light = Path()
        let side: CGFloat = waxing ? 1 : -1
        for i in 0...48 {
            let a = -.pi / 2 + Double(i) * .pi / 48
            let p = CGPoint(x: rect.midX + side * radius * cos(a), y: rect.midY + radius * sin(a))
            if i == 0 { light.move(to: p) } else { light.addLine(to: p) }
        }
        for i in (0...48).reversed() {
            let a = -.pi / 2 + Double(i) * .pi / 48
            light.addLine(to: CGPoint(x: rect.midX + side * (1-2*fraction) * radius * cos(a), y: rect.midY + radius*sin(a)))
        }
        light.closeSubpath()
        return light
    }
}
