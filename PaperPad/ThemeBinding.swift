import SwiftUI

/// The binding is fixed to the pad while the printed sheet moves underneath it.
struct ThemeBinding: View {
    let theme: DailyTheme

    var body: some View {
        if theme == .editorialDay || theme == .deskLedger || theme == .moon || theme == .nihon || theme == .illyeok {
            Group {
                if theme == .editorialDay {
                    EditorialLinen()
                } else if theme == .illyeok {
                    IllyeokBinding()
                } else if theme == .nihon {
                    ZStack {
                        LinearGradient(colors: [Color(white: 0.92), Color(white: 0.82)], startPoint: .top, endPoint: .bottom)
                        Canvas { ctx, size in
                            let left = CGPoint(x: size.width * 0.18, y: size.height * 0.53)
                            let right = CGPoint(x: size.width * 0.82, y: left.y)
                            let knot = CGPoint(x: size.width * 0.52, y: left.y + 1)
                            for hole in [left, right] {
                                ctx.fill(Path(ellipseIn: CGRect(x: hole.x-2.8, y: hole.y-2.8, width: 5.6, height: 5.6)),
                                         with: .color(Color(white: 0.24)))
                            }
                            var cord = Path()
                            cord.move(to: left)
                            cord.addQuadCurve(to: right, control: CGPoint(x: knot.x, y: knot.y + 2))
                            cord.move(to: CGPoint(x: knot.x-14, y: knot.y+6))
                            cord.addQuadCurve(to: knot, control: CGPoint(x: knot.x-8, y: knot.y+1))
                            cord.addQuadCurve(to: CGPoint(x: knot.x+15, y: knot.y+6), control: CGPoint(x: knot.x+6, y: knot.y+2))
                            ctx.stroke(cord, with: .color(NihonFace.blue), style: StrokeStyle(lineWidth: 2.7, lineCap: .round))
                            ctx.stroke(cord, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
                        }
                    }
                } else if theme == .moon {
                    LinearGradient(colors: [Color(white: 0.54), MoonFace.blue], startPoint: .top, endPoint: .bottom)
                } else {
                    LinearGradient(stops: [
                        .init(color: Color(white: 0.88), location: 0),
                        .init(color: Color(white: 0.81), location: 0.09),
                        .init(color: Color(white: 0.77), location: 0.82),
                        .init(color: Color(white: 0.74), location: 1)
                    ], startPoint: .top, endPoint: .bottom)
                    .overlay(alignment: .top) {
                        Rectangle().fill(.white.opacity(0.52)).frame(height: 0.6)
                    }
                }
            }
                .frame(width: Metrics.pageW, height: Metrics.bindingH)
                .clipShape(RoundedRectangle(cornerRadius: theme == .editorialDay ? 3 : 1.6))
                .shadow(color: .black.opacity(0.16), radius: 0.8, y: 1)
                #if os(macOS)
                .contentShape(Rectangle()).windowDragHandle()
                #else
                .allowsHitTesting(false)
                #endif
                .accessibilityHidden(true)
        } else if theme == .celestialAlmanac {
            CelestialBinding()
                #if os(macOS)
                .contentShape(Rectangle()).windowDragHandle()
                #else
                .allowsHitTesting(false)
                #endif
        } else if theme == .fuji {
            FujiClip()
                #if os(macOS)
                .windowDragHandle()
                #endif
        } else {
            PadBinding(warmGray: theme == .tungShing)
        }
    }
}

private struct EditorialLinen: View {
    var body: some View {
        LinearGradient(colors: [Color(white: 0.48), Color(white: 0.43)],
                       startPoint: .top, endPoint: .bottom)
            .overlay {
                Canvas { context, size in
                    var threads = Path()
                    // Offset alternate rows of short threads to suggest a plain weave.
                    for row in 0..<Int(ceil(size.height / 2.5)) {
                        let y = CGFloat(row) * 2.5 + 1
                        let phase: CGFloat = row.isMultiple(of: 2) ? 0 : 2
                        for x in stride(from: phase, to: size.width, by: 4) {
                            threads.move(to: CGPoint(x: x, y: y))
                            threads.addLine(to: CGPoint(x: x + 1.7, y: y))
                        }
                    }
                    context.stroke(threads, with: .color(.white.opacity(0.13)), lineWidth: 0.55)
                }
            }
    }
}
