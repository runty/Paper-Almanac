//
//  MonthGrid.swift
//  himekuri
//
//  The mini month calendar printed at the foot of every page.
//

import SwiftUI

struct MonthGrid: View {
    let info: DayInfo
    let t: PageTheme
    var design: Font.Design = .serif
    var latinHeader = false
    /// Override the weekday header glyphs (e.g. 日一二…六 for the huangli).
    var customHeaders: [String]? = nil
    var scale: CGFloat = 1

    var body: some View {
        let weeks = info.grid
        let headers = customHeaders ?? (latinHeader
            ? ["S", "M", "T", "W", "T", "F", "S"]
            : ["日", "月", "火", "水", "木", "金", "土"])
        VStack(spacing: 2.5 * scale) {
            HStack(spacing: 7.5 * scale) {
                ForEach(0..<7, id: \.self) { i in
                    Text(verbatim: headers[i])
                        .font(latinHeader
                            ? .system(size: 7 * scale, weight: .bold, design: design)
                            : Theme.kanji(7 * scale))
                        .foregroundStyle(columnColor(i))
                        .frame(width: 12 * scale)
                }
            }
            ForEach(weeks.indices, id: \.self) { r in
                HStack(spacing: 7.5 * scale) {
                    ForEach(0..<7, id: \.self) { c in
                        cell(weeks[r][c], column: c)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ d: Int?, column c: Int) -> some View {
        if let d {
            let isToday = d == info.day
            Text(verbatim: "\(d)")
                .font(.system(size: 8 * scale, weight: isToday ? .black : .semibold, design: design).monospacedDigit())
                .foregroundStyle(isToday ? t.paper : columnColor(c))
                .frame(width: 12 * scale, height: 11 * scale)
                .background(
                    isToday ? AnyShapeStyle(t.accent(for: info)) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 2 * scale)
                )
        } else {
            Color.clear.frame(width: 12 * scale, height: 11 * scale)
        }
    }

    private func columnColor(_ c: Int) -> Color {
        c == 0 ? t.sunday : c == 6 ? t.saturday : t.ink
    }
}
