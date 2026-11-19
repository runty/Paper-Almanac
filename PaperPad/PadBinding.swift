//
//  PadBinding.swift
//  himekuri
//
//  The stapled binding across the top of the pad. It doubles as the
//  handle: dragging it moves the window around the desk.
//

import SwiftUI

struct PadBinding: View {
    var warmGray = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    colors: warmGray
                        ? [Color(red: 0.86, green: 0.84, blue: 0.81),
                           Color(red: 0.81, green: 0.79, blue: 0.76)]
                        : [Color(white: 0.985), Color(white: 0.86)],
                    startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5))
                .overlay(alignment: .top) {
                    if !warmGray {
                        Rectangle()
                            .fill(Ink.vermilion.opacity(0.9))
                            .frame(height: 2.5)
                            .padding(.horizontal, 2)
                            .padding(.top, 0.5)
                    }
                }
            HStack {
                staple
                Spacer()
                if !warmGray {
                    hangingHole
                    Spacer()
                }
                staple
            }
            .padding(.horizontal, 46)
        }
        .frame(width: warmGray ? Metrics.pageW : Metrics.pageW + 10, height: Metrics.bindingH)
        .shadow(color: .black.opacity(0.18), radius: 2, y: 1.5)
        .contentShape(Rectangle())
        #if os(macOS)
        .windowDragHandle()
        #endif
    }

    private var staple: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(LinearGradient(
                colors: [Color(white: 0.55), Color(white: 0.75), Color(white: 0.45)],
                startPoint: .top, endPoint: .bottom))
            .frame(width: 16, height: 3.5)
    }

    private var hangingHole: some View {
        Circle()
            .fill(Color.black.opacity(0.32))
            .overlay(Circle().strokeBorder(Color.black.opacity(0.35), lineWidth: 1))
            .frame(width: 9, height: 9)
    }
}
