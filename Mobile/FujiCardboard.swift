import SwiftUI

/// A punched sheet of warm kraft board, fixed behind the tearable pad.
struct FujiCardboard: View {
    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size)
            var cutout = Path(bounds)
            let hole = CGRect(x: size.width / 2 - 10, y: 17, width: 20, height: 20)
            cutout.addEllipse(in: hole)
            context.clip(to: cutout, style: FillStyle(eoFill: true))
            context.fill(Path(bounds), with: .linearGradient(
                Gradient(colors: [Color(red: 0.87, green: 0.74, blue: 0.59),
                                  Color(red: 0.77, green: 0.61, blue: 0.46)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            var fibers = SeededRandom(seed: 4550723)
            for _ in 0..<12000 {
                let x = fibers.cg(0...size.width)
                let y = fibers.cg(0...size.height)
                let dark = fibers.unit() < 0.6
                let fleck = CGRect(x: x, y: y, width: fibers.cg(0.25...1.4), height: fibers.cg(0.3...1.9))
                context.fill(Path(ellipseIn: fleck), with: .color((dark ? Color.brown : .white).opacity(0.16)))
            }
            context.stroke(Path(ellipseIn: hole), with: .color(.brown.opacity(0.35)), lineWidth: 1.3)
        }
        .shadow(color: .black.opacity(0.19), radius: 3, x: 1, y: 3)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
