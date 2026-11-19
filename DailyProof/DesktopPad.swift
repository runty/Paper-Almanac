import SwiftUI

/// The same 300 × 400 pt stock, top binding and edge offsets as Himekuri.
/// The 4:5 printed area occupies the 375 pt below the binding allowance.
struct DesktopPad: View {
    let page: PrintedDay
    private var remaining: Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let components = DateComponents(year: Int(page.date.year), month: Int(page.date.month), day: Int(page.date.day))
        guard let date = calendar.date(from: components),
              let ordinal = calendar.ordinality(of: .day, in: .year, for: date),
              let year = calendar.range(of: .day, in: .year, for: date) else { return 0 }
        return 1 - Double(ordinal) / Double(year.count)
    }

    var body: some View {
        ZStack(alignment: .top) {
            let layers = max(4, Int(remaining * 22))
            ForEach((1...layers).reversed(), id: \.self) { layer in
                let depth = CGFloat(layer)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.98 - 0.12 * depth / CGFloat(layers)))
                    .frame(width: Metrics.pageW, height: Metrics.pageH)
                    .offset(x: 0.55 * depth, y: Metrics.pageTopInset + 0.85 * depth)
            }
            VStack(spacing: 0) {
                Color(white: 0.99).frame(height: 25)
                PrintFace(day: page).scaleEffect(0.75).frame(width: Metrics.pageW, height: 375)
            }.frame(width: Metrics.pageW, height: Metrics.pageH).clipShape(RoundedRectangle(cornerRadius: 2)).offset(y: Metrics.pageTopInset)
            PadBinding()
        }
        .frame(width: 340, height: 428)
        .compositingGroup()
        .shadow(color: .black.opacity(0.16), radius: 4, y: 3)
    }
}
