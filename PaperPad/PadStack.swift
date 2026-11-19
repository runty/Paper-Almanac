//
//  PadStack.swift
//  himekuri
//
//  The unturned pages beneath the top sheet, thicker while the year is young.
//

import SwiftUI

struct PadStack: View {
    let remainingFraction: Double
    let theme: PageTheme

    var body: some View {
        #if os(macOS)
        let stackDepth = 32 * remainingFraction
        let layers = Int(ceil(stackDepth))
        #else
        let layers = max(4, Int(remainingFraction * 22))
        let stackDepth = CGFloat(layers)
        #endif
        return ZStack(alignment: .top) {
            ForEach(0..<layers, id: \.self) { i in
                let depth = CGFloat(stackDepth) - CGFloat(i)
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.paper.mix(with: theme.edge, by: Double(depth) / Double(stackDepth) * 0.9))
                    .frame(width: Metrics.pageW, height: Metrics.pageH)
                    .offset(x: depth * 0.55, y: Metrics.pageTopInset + depth * 0.85)
            }
        }
        .compositingGroup()
        .opacity(theme.paperOpacity)
        .allowsHitTesting(false)
    }
}
