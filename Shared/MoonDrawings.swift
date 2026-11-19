import SwiftUI

/// Schematic star figures drawn as they appear on a north-up chart.
struct ConstellationDrawing: View {
    let constellation: EveningConstellation

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 100, y: size.height / 100)
            let strokes: [[CGPoint]]
            switch constellation {
            case .orion:
                let belt = [CGPoint(x: 47, y: 53), CGPoint(x: 52, y: 49), CGPoint(x: 57, y: 45)]
                strokes = [[.init(x: 26, y: 17), .init(x: 65, y: 11), belt[2]],
                           [belt[0], .init(x: 26, y: 17)], belt,
                           [belt[0], .init(x: 39, y: 92), .init(x: 79, y: 83), belt[2]]]
            case .leo:
                strokes = [[.init(x: 67, y: 12), .init(x: 81, y: 16), .init(x: 86, y: 29),
                            .init(x: 73, y: 41), .init(x: 69, y: 54), .init(x: 73, y: 76),
                            .init(x: 12, y: 71), .init(x: 32, y: 48), .init(x: 73, y: 41)]]
            case .cygnus:
                let center = CGPoint(x: 51, y: 48)
                strokes = [[.init(x: 33, y: 15), center, .init(x: 74, y: 90)],
                           [.init(x: 8, y: 70), .init(x: 27, y: 60), center,
                            .init(x: 72, y: 38), .init(x: 91, y: 30)]]
            case .crux:
                strokes = [[.init(x: 48, y: 12), .init(x: 55, y: 88)],
                           [.init(x: 24, y: 44), .init(x: 82, y: 40)]]
            case .grus:
                strokes = [[.init(x: 12, y: 24), .init(x: 34, y: 35), .init(x: 52, y: 46),
                            .init(x: 66, y: 69), .init(x: 82, y: 82)],
                           [.init(x: 52, y: 46), .init(x: 29, y: 60), .init(x: 66, y: 69)]]
            case .pegasus:
                strokes = [[.init(x: 23, y: 26), .init(x: 68, y: 20), .init(x: 72, y: 65),
                            .init(x: 20, y: 72), .init(x: 23, y: 26)],
                           [.init(x: 72, y: 65), .init(x: 82, y: 77), .init(x: 92, y: 83)]]
            }
            for points in strokes {
                var path = Path()
                path.addLines(points)
                context.stroke(path, with: .color(MoonFace.blue.opacity(0.70)), lineWidth: 0.75)
            }
            for point in strokes.joined() {
                context.fill(Path(ellipseIn: CGRect(x: point.x - 1.9, y: point.y - 1.9, width: 3.8, height: 3.8)),
                             with: .color(MoonFace.blue))
            }
        }
    }
}

struct MissionDrawing: View {
    let mission: SpaceMilestone.Drawing

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 60, y: size.height / 60)
            let ink = GraphicsContext.Shading.color(MoonFace.blue)
            func line(_ points: (CGFloat, CGFloat)...) {
                var path = Path()
                path.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
                ctx.stroke(path, with: ink, style: StrokeStyle(lineWidth: 1.45, lineCap: .round, lineJoin: .round))
            }
            func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
                ctx.stroke(Path(ellipseIn: .init(x: x, y: y, width: w, height: h)), with: ink, lineWidth: 1.4)
            }
            switch mission {
            case .eagle:
                line((21,29),(19,22),(24,14),(35,14),(41,23),(37,29),(21,29))
                line((23,22),(26,17),(30,22),(23,22))
                line((20,30),(39,30),(39,36),(20,36),(20,30))
                line((22,36),(13,48),(21,42),(29,36))
                line((37,36),(47,48),(39,42),(33,36))
                line((9,49),(17,49)); line((43,49),(51,49))
                line((28,37),(26,43),(34,43),(32,37))
                line((35,14),(38,9)); oval(35,6,8,4)
            case .sputnik:
                oval(8,9,25,25)
                line((13,27),(19,48)); line((20,31),(34,55))
                line((27,30),(46,49)); line((31,24),(53,40))
                line((12,18),(17,13),(23,12))
            case .hubble:
                ctx.translateBy(x: 30, y: 30); ctx.rotate(by: .degrees(-30))
                line((-7,-17),(-7,19),(7,19),(7,-17))
                oval(-7,-20,14,6); line((-7,10),(7,10)); line((-7,14),(7,14))
                for side: CGFloat in [-1, 1] {
                    line((7*side,-1),(12*side,-1))
                    line((12*side,-8),(23*side,-8),(23*side,6),(12*side,6),(12*side,-8))
                    line((17*side,-8),(17*side,6)); line((12*side,-1),(23*side,-1))
                }
            case .voyager:
                ctx.translateBy(x: 30, y: 30); ctx.rotate(by: .degrees(-25))
                oval(-17,-9,34,6)
                var dish = Path()
                dish.move(to: .init(x: -17, y: -6))
                dish.addQuadCurve(to: .init(x: 17, y: -6), control: .init(x: 0, y: 16))
                ctx.stroke(dish, with: ink, lineWidth: 1.5)
                line((-11,-7),(0,-19),(10,-7)); line((0,-19),(0,-7))
                line((-5,5),(-6,12),(6,12),(5,5))
                line((2,13),(22,22)); line((1,16),(20,24)); line((-5,12),(-22,21))
            }
        }
    }
}
