import SwiftUI

/// The cord and riveted paper strip stay on the wall as the page tears away.
struct CelestialBinding: View {
    #if os(macOS)
    // The desktop pad has a fixed transparent margin above the tear line.
    private let cordHeight: CGFloat = Metrics.blockTopPad - 8
    private let stripHeight: CGFloat = Metrics.bindingH + 8
    #else
    private let cordHeight: CGFloat = 40
    private let stripHeight: CGFloat = 43
    static let headroom: CGFloat = 40 + 43 - Metrics.bindingH
    #endif

    var body: some View {
        VStack(spacing: 0) {
            Canvas { context, size in
                let w = size.width, h = size.height
                var braid = Path()
                braid.move(to: CGPoint(x: 0.12 * w, y: h + 1))
                braid.addQuadCurve(to: CGPoint(x: 0.51 * w, y: 0.43 * h),
                                   control: CGPoint(x: 0.34 * w, y: 0.68 * h))
                braid.addQuadCurve(to: CGPoint(x: 0.535 * w, y: 0.08 * h),
                                   control: CGPoint(x: 0.53 * w, y: 0.37 * h))
                braid.move(to: CGPoint(x: 0.52 * w, y: 0.38 * h))
                braid.addQuadCurve(to: CGPoint(x: 0.89 * w, y: h + 1),
                                   control: CGPoint(x: 0.62 * w, y: 0.58 * h))
                let pin = CGRect(x: 0.535 * w - 1.7, y: 0.08 * h - 1.7, width: 3.4, height: 3.4)
                context.stroke(braid, with: .color(Color(red: 0.41, green: 0.36, blue: 0.36)), lineWidth: 1.9)
                context.stroke(braid, with: .color(Color(white: 0.96)),
                               style: StrokeStyle(lineWidth: 1.3, lineCap: .round, dash: [1.25, 1.5]))
                context.fill(Path(ellipseIn: pin), with: .color(Color(white: 0.46)))
                context.stroke(Path(ellipseIn: pin), with: .color(.white.opacity(0.75)), lineWidth: 0.5)
            }
            .frame(height: cordHeight)
            .shadow(color: .black.opacity(0.35), radius: 0.6, x: 1, y: 1)

            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.982, green: 0.969, blue: 0.953),
                                               Color(red: 0.903, green: 0.881, blue: 0.855)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { PaperGrain(seed: 2250, strength: 1.8) }
                .overlay {
                    HStack {
                        fastener
                        Spacer()
                        fastener
                    }.padding(.horizontal, 26)
                }
                .overlay(alignment: .bottom) { Rectangle().fill(.black.opacity(0.14)).frame(height: 0.6) }
                .frame(height: stripHeight)
        }
        .frame(width: Metrics.pageW, height: Metrics.bindingH, alignment: .bottom)
        .accessibilityHidden(true)
    }

    private var fastener: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(white: 0.71), Color(red: 0.84, green: 0.83, blue: 0.87),
                                           Color(white: 0.94), .white],
                                 center: UnitPoint(x: 0.47, y: 0.48), startRadius: 0.5, endRadius: 13))
            .overlay {
                Circle().strokeBorder(LinearGradient(colors: [.white, .white, .black.opacity(0.24)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            }
            .frame(width: 27, height: 27)
            .shadow(color: .black.opacity(0.15), radius: 0.4, x: 0.5, y: 0.5)
    }
}
