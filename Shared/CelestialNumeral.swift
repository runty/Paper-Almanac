import SwiftUI

/// Single-stroke printing figures. Coordinates share a 50 × 90 design grid.
struct CelestialNumeral: View {
    let day: Int
    let height: CGFloat
    private var digits: [Int] { String(day).compactMap(\.wholeNumberValue) }
    private func width(_ n: Int) -> CGFloat { n == 1 ? 22 : 50 }

    var body: some View {
        let advance = digits.map(width).reduce(0, +) + CGFloat(digits.count - 1) * 10
        Canvas { context, size in
            let scale = size.height / 100
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: 5, y: 5)
            for digit in digits {
                let path = Self.figure(digit)
                context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: 7.2, lineCap: .round, lineJoin: .round))
                if digit == 1 {
                    context.fill(Path(ellipseIn: CGRect(x: 0, y: 8, width: 6, height: 6)), with: .foreground)
                }
                context.translateBy(x: width(digit) + 10, y: 0)
            }
        }
        .frame(width: (advance + 10) * height / 100, height: height)
        .accessibilityLabel(Text(verbatim: String(day)))
    }

    private static func figure(_ n: Int) -> Path {
        var p = Path()
        func move(_ x: CGFloat, _ y: CGFloat) { p.move(to: CGPoint(x: x, y: y)) }
        func line(_ x: CGFloat, _ y: CGFloat) { p.addLine(to: CGPoint(x: x, y: y)) }
        func curve(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat, _ x: CGFloat, _ y: CGFloat) {
            p.addCurve(to: CGPoint(x: x,y: y), control1: CGPoint(x: a,y: b), control2: CGPoint(x: c,y: d))
        }
        switch n {
        case 0:
            p.addRoundedRect(in: CGRect(x: 1, y: 0, width: 48, height: 90), cornerSize: CGSize(width: 24, height: 24))
        case 1:
            move(20,0); line(20,90)
        case 2:
            move(1,23); curve(3,-9,49,-9,49,23); curve(49,33,43,41,37,50); line(1,90); line(50,90)
        case 3:
            move(3,4); line(47,4); line(22,41); curve(55,36,60,85,30,90); curve(16,93,5,87,0,77)
        case 4:
            move(36,0); line(0,59); line(50,59); move(37,30); line(37,90)
        case 5:
            move(48,1); line(7,1); line(5,43); curve(23,30,50,40,50,64); curve(50,94,13,100,1,78)
        case 6:
            move(39,0); curve(22,18,1,40,1,64); curve(1,100,50,100,50,65); curve(50,34,9,33,2,58)
        case 7:
            move(1,1); line(49,1); line(12,90)
        case 8:
            p.addEllipse(in: CGRect(x: 4, y: 0, width: 42, height: 41))
            p.addEllipse(in: CGRect(x: 0, y: 41, width: 50, height: 49))
        default:
            move(12,90); curve(26,69,49,46,49,25); curve(49,-9,0,-9,0,25); curve(0,57,41,59,48,32)
        }
        return p
    }
}
