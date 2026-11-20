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
    static func constrainedOrigin(_ frame: NSRect, within screen: NSRect, theme: DailyTheme, scale: CGFloat) -> NSPoint {
        let sideInset = (frame.width - theme.desktopVisibleWidth * scale) / 2
        let topInset = theme.desktopVisibleTop * scale
        let minimumX = screen.minX - sideInset
        let maximumX = screen.maxX - frame.width + sideInset
        let minimumY = screen.minY - frame.height + topInset + Metrics.bindingH * scale
        let maximumY = screen.maxY - frame.height + topInset
        return NSPoint(x: max(minimumX, min(frame.minX, maximumX)),
                       y: max(minimumY, min(frame.minY, maximumY)))
    }

    var isOnFullScreenDisplay: Bool {
        guard let display = screen ?? NSScreen.main, let primary = NSScreen.screens.first,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                       kCGNullWindowID) as? [[String: Any]] else { return false }
        let screenBounds = CGRect(x: display.frame.minX, y: primary.frame.maxY - display.frame.maxY,
                                  width: display.frame.width, height: display.frame.height)
        let ownPID = ProcessInfo.processInfo.processIdentifier
        // Compare window geometry only. In-place video full screen can leave the active Space unchanged.
        return windows.contains { window in
            guard let owner = window[kCGWindowOwnerPID as String] as? pid_t, owner != ownPID,
                  window[kCGWindowLayer as String] as? Int == Int(CGWindowLevelForKey(.normalWindow)),
                  (window[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                  let geometry = window[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: geometry as CFDictionary) else { return false }
            let tolerance: CGFloat = 2
            return abs(bounds.minX - screenBounds.minX) <= tolerance &&
                   abs(bounds.minY - screenBounds.minY) <= tolerance &&
                   abs(bounds.maxX - screenBounds.maxX) <= tolerance &&
                   abs(bounds.maxY - screenBounds.maxY) <= tolerance
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
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
