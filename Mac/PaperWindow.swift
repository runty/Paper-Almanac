//
//  PaperWindow.swift
//  himekuri
//
//  A borderless, transparent window that behaves like an object on the desk:
//  clicks outside the pad fall through to whatever is underneath.
//

import AppKit
import SwiftUI

final class PaperWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class PassThroughHostingView: NSHostingView<ContentView> {
    /// Region (top-left origin coordinates) that accepts mouse events.
    var interactiveRect: CGRect = .zero

    required init(rootView: ContentView) {
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let topLeft = isFlipped ? local : NSPoint(x: local.x, y: bounds.height - local.y)
        if let board = rootView.store.theme.desktopBoardSize {
            let scale = rootView.pageScale
            let boardRect = CGRect(x: bounds.midX - board.width * scale / 2,
                                   y: DailyTheme.desktopBoardTop * scale,
                                   width: board.width * scale, height: board.height * scale)
            guard boardRect.contains(topLeft) else { return nil }
        } else if !interactiveRect.contains(topLeft) {
            return nil
        }
        return super.hitTest(point)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
