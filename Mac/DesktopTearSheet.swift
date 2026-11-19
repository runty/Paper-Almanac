import SwiftUI

struct DesktopTearSheet: View {
    struct Identity: Hashable {
        let day: String
        let theme: DailyTheme
        let calendarLayout: Bool
        let scale: CGFloat
    }

    @ObservedObject var store: PadStore
    let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @State private var scene: MetalPaperScene?
    @State private var held = false
    @State private var retainedBonds: [UInt32]?
    @GestureState private var gestureActive = false

    private var face: SheetView {
        SheetView(sheet: store.top, theme: store.theme, calendarLayout: store.calendarLayout)
    }

    var body: some View {
        ZStack {
            face.opacity(scene == nil ? 1 : 0)
            if scene != nil {
                // The fixed half of the perforation stays under the binding.
                face.mask(StubShape(seed: tearSeed(for: store.tornCount)))
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(drag)
        .onContinuousHover { phase in
            if case .active(let point) = phase, canGrab(point) {
                (held ? NSCursor.closedHand : .openHand).set()
            } else { NSCursor.arrow.set() }
        }
        .onAppear { if !reducedMotion { MetalPaperScene.prepare() } }
        .onChange(of: gestureActive) { if !gestureActive && held { settle() } }
        .onChange(of: reducedMotion) { cancel() }
        .onDisappear { cancel() }
    }

    private func canGrab(_ point: CGPoint) -> Bool { point.y >= Metrics.pageH * (1 - Metrics.tearZone) }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 6)
            .updating($gestureActive) { _, active, _ in active = true }
            .onChanged { value in
                guard store.canTear, canGrab(value.startLocation) else { return }
                if !held {
                    cancel()
                    held = true
                    if !reducedMotion, let image = Snapshot.cgImage(of: face, scale: 2 * scale) {
                        scene = MetalPaperScene(image: image, seed: tearSeed(for: store.tornCount),
                                                grab: value.startLocation, scale: scale, theme: store.theme, retainedBonds: retainedBonds)
                    }
                    NSCursor.closedHand.set()
                }
                scene?.pull(value.translation)
            }
            .onEnded { value in
                guard held else { return }
                NSCursor.openHand.set()
                scene?.pull(value.translation)
                if let scene {
                    let bonds = scene.bindingState()
                    retainedBonds = bonds
                    guard scene.canDetach(with: bonds) else { settle(); return }
                } else if MetalPaperScene.tension(at: value.startLocation, pull: value.translation) < Metrics.tearThreshold {
                    settle()
                    return
                }
                guard store.canTear else { settle(); return }
                held = false
                if let scene {
                    scene.drop(velocity: value.velocity)
                    self.scene = nil // The display link owns the falling sheet.
                } else {
                    TearSound.shared.playRip()
                    Haptics.rip()
                }
                store.tear()
            }
    }

    private func settle() {
        held = false
        NSCursor.openHand.set()
        scene?.settle { scene = nil }
    }

    private func cancel() {
        held = false
        scene?.close()
        scene = nil
    }
}

@MainActor private extension MetalPaperScene {
    convenience init?(image: CGImage, seed: UInt64, grab: CGPoint, scale: CGFloat, theme: DailyTheme, retainedBonds: [UInt32]?) {
        guard let pad = NSApp.windows.first(where: { $0 is PaperWindow }), let screen = pad.screen else { return nil }
        let canvas = NSRect(x: pad.frame.midX - 570*scale, y: screen.frame.minY,
                            width: 1140*scale, height: screen.frame.height).intersection(screen.frame)
        let origin = CGPoint(x: pad.frame.midX - Metrics.pageW*scale/2 - canvas.minX,
                             y: canvas.maxY - pad.frame.maxY + (theme.blockTopPad + Metrics.pageTopInset)*scale)
        self.init(image: image, seed: seed, grab: grab, scale: scale, retainedBonds: retainedBonds,
                  canvas: canvas.size, sheetOrigin: origin, theme: theme)
        let window = NSWindow(contentRect: canvas, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = pad.level
        window.collectionBehavior = pad.collectionBehavior
        window.contentView = view
        pad.addChildWindow(window, ordered: .above)
        window.orderFront(nil)
        start {
            window.parent?.removeChildWindow(window)
            window.orderOut(nil)
            window.contentView = nil
            window.close()
        }
    }
}
