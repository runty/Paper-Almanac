import SwiftUI
import AppKit

extension View {
    func windowDragHandle() -> some View {
        modifier(CalendarWindowDrag())
    }
}

private struct CalendarWindowDrag: ViewModifier {
    @State private var startMouse: NSPoint?
    @State private var startFrame: NSRect?

    func body(content: Content) -> some View {
        content.gesture(DragGesture(minimumDistance: 1)
            .onChanged { _ in
                guard let window = NSApp.windows.first(where: { $0 is PaperWindow }) as? PaperWindow,
                      let host = window.contentView as? PassThroughHostingView else { return }
                let mouse = NSEvent.mouseLocation
                if startMouse == nil {
                    startMouse = mouse
                    startFrame = window.frame
                }
                guard let startMouse, let startFrame else { return }
                var origin = NSPoint(x: startFrame.minX + mouse.x - startMouse.x,
                                     y: startFrame.minY + mouse.y - startMouse.y)
                if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? window.screen {
                    origin = PaperWindow.constrainedOrigin(NSRect(origin: origin, size: startFrame.size),
                                                          within: screen.visibleFrame,
                                                          theme: host.rootView.store.theme, scale: host.rootView.pageScale)
                }
                window.setFrameOrigin(origin)
            }
            .onEnded { _ in
                startMouse = nil
                startFrame = nil
            })
    }
}
