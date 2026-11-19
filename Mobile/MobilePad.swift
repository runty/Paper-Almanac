import SwiftUI

struct MobilePad: View {
    @ObservedObject var store: PadStore
    let theme: DailyTheme
    let calendarLayout: Bool
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    let pageScale: CGFloat
    @Environment(\.displayScale) private var displayScale
    @Environment(\.scenePhase) private var scenePhase
    @State private var anchor = MobilePaperAnchor()
    @State private var paper: MetalPaperScene?
    @State private var falling: MetalPaperScene?
    @State private var fallingDestination: String?
    @State private var retainedBonds: [UInt32]?
    @State private var intent: DragIntent?
    @GestureState private var fingerDown = false

    private enum DragIntent { case tear, consumed }

    var body: some View {
        ZStack(alignment: .top) {
            if theme == .fuji {
                FujiPaperStack(remainingFraction: store.remainingFraction)
            } else {
                PadStack(remainingFraction: store.remainingFraction, theme: theme.original ?? .tongsheng)
            }
            if paper != nil, store.canTear {
                SheetView(sheet: store.next, theme: theme, calendarLayout: calendarLayout)
                    .overlay(Color.black.opacity(0.075))
                    .allowsHitTesting(false).accessibilityHidden(true)
                    .offset(y: Metrics.pageTopInset)
            }
            ZStack {
                face.opacity(paper == nil ? 1 : 0)
                if paper != nil {
                    face.mask(StubShape(seed: tearSeed(for: store.tornCount)))
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
                .background { PaperAnchorView(anchor: anchor).allowsHitTesting(false) }
                .overlayPreferenceValue(DayNumberBounds.self) { anchor in
                    if let anchor {
                        GeometryReader { geometry in
                            let bounds = geometry[anchor]
                            Color.clear
                                .frame(width: bounds.width, height: bounds.height)
                                .contentShape(Rectangle())
                                .onTapGesture { store.today() }
                                .position(x: bounds.midX, y: bounds.midY)
                        }
                    }
                }
                .offset(y: Metrics.pageTopInset)
            if store.tornCount > 0 {
                PadStubs(tornCount: store.tornCount, theme: theme.original ?? .tongsheng)
                    .offset(y: Metrics.pageTopInset)
            }
        }
        .frame(width: 310, height: 418, alignment: .top)
        .overlay(alignment: .top) { ThemeBinding(theme: theme).allowsHitTesting(false) }
        .shadow(color: .black.opacity(0.17), radius: 5, y: 3)
        .contentShape(Rectangle()).simultaneousGesture(drag)
        .accessibilityElement(children: .ignore).accessibilityLabel(accessibleReading)
        .accessibilityIdentifier("daily-sheet-" + store.top.label + (store.top.page == nil ? "-pending" : ""))
        .accessibilityHint("Activate to return to today. Use the Actions rotor to browse days.")
        .accessibilityAction { store.today() }
        .activityListActions(store: store, enabled: theme.offersActivityLists)
        .accessibilityAction(named: "Today") { store.today() }
        .accessibilityAction(named: "Previous day") { store.step(-1) }
        .accessibilityAction(named: "Next day") { store.step(1) }
        .accessibilityAction(named: "Tear to next day") { store.tear() }
        .onAppear { if !reducedMotion { MetalPaperScene.prepare() } }
        .onChange(of: store.top.label) {
            if intent == .tear { intent = .consumed }
            clearHeldSheet()
            retainedBonds = nil
            if fallingDestination != store.top.label { clearFallingSheet() }
        }
        .onChange(of: theme) { cancelInteraction(); retainedBonds = nil }
        .onChange(of: calendarLayout) { cancelInteraction() }
        .onChange(of: pageScale) { cancelInteraction() }
        .onChange(of: reducedMotion) { cancelInteraction() }
        .onChange(of: scenePhase) { if scenePhase != .active { cancelInteraction() } }
        .onDisappear { cancelInteraction() }
        .onChange(of: fingerDown) {
            if !fingerDown, intent != nil {
                if intent == .tear { settle() }
                intent = nil
            }
        }
    }

    private var accessibleReading: String {
        guard let page = store.top.page else { return store.top.description }
        if !theme.offersActivityLists { return store.top.description(for: theme, calendarLayout: calendarLayout) }
        let term = page.report.termOnDate ?? page.report.nextTerm
        let prefix = page.report.termOnDate == nil ? "Next solar term" : "Solar term"
        return [page.report.weekdayLabel, page.report.lunarMonthLabel + page.report.lunarDayLabel,
                page.holiday?.english, prefix + ", " + termName(term) + ", " + term.date.label,
                store.top.description(for: theme, calendarLayout: calendarLayout)].compactMap { $0 }.joined(separator: ". ")
    }

    private var face: SheetView {
        SheetView(sheet: store.top, theme: theme, calendarLayout: calendarLayout)
    }

    private var printedPaper: CGRect {
        CGRect(x: (310 - Metrics.pageW) / 2, y: Metrics.bindingH, width: Metrics.pageW,
               height: Metrics.pageTopInset + Metrics.pageH - Metrics.bindingH)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 7, coordinateSpace: .local)
            .updating($fingerDown) { _, down, _ in down = true }
            .onChanged { value in
                let delta = value.translation
                if intent == nil {
                    let start = value.startLocation
                    guard printedPaper.contains(start), store.top.page != nil else {
                        intent = .consumed
                        return
                    }
                    intent = .tear
                    clearHeldSheet()
                    clearFallingSheet()
                    if !reducedMotion, let image = Snapshot.cgImage(of: face, scale: displayScale * pageScale) {
                        paper = anchor.begin(image: image, seed: tearSeed(for: store.tornCount),
                                             grab: sheetPoint(start), retainedBonds: retainedBonds)
                    }
                }
                if intent == .tear { paper?.pull(delta, loadsBinding: loadsBinding(delta)) }
            }
            .onEnded { value in
                defer { intent = nil }
                guard intent == .tear else { return }
                guard store.canTear else { settle(); return }
                if let paper {
                    paper.pull(value.translation, loadsBinding: loadsBinding(value.translation))
                    let bonds = paper.bindingState()
                    retainedBonds = bonds
                    guard paper.canDetach(with: bonds) else { settle(); return }
                    self.paper = nil
                    falling = paper
                    fallingDestination = store.next.label
                    paper.drop(velocity: value.velocity) {
                        falling = nil
                        fallingDestination = nil
                    }
                } else {
                    // Without a simulated seam, reserve the fallback turn for a
                    // deliberate lift or downward tug. A lateral swipe only grips.
                    let pull = value.translation
                    guard loadsBinding(pull),
                          MetalPaperScene.tension(at: sheetPoint(value.startLocation), pull: pull) >= Metrics.tearThreshold else { return }
                    TearSound.shared.playRip()
                    Haptics.rip()
                }
                store.tear()
            }
    }

    // Let a finger sweep across the sheet to lift it. Reevaluate as the
    // finger turns so the same grip can develop into a deliberate tear.
    private func loadsBinding(_ pull: CGSize) -> Bool {
        abs(pull.height) > abs(pull.width) * 0.24
    }

    private func sheetPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x - printedPaper.minX, y: point.y - Metrics.pageTopInset)
    }

    private func settle() {
        paper?.settle { paper = nil }
    }

    private func clearHeldSheet() {
        paper?.close()
        paper = nil
    }

    private func clearFallingSheet() {
        falling?.close()
        falling = nil
        fallingDestination = nil
    }

    private func cancelInteraction() {
        if intent != nil { intent = .consumed }
        clearHeldSheet()
        clearFallingSheet()
    }
}

// Convert the actual printed face into its containing window's coordinates.
// This tracks the theme's binding, safe areas and iPad window size.
@MainActor private final class MobilePaperAnchor {
    weak var marker: UIView?

    func begin(image: CGImage, seed: UInt64, grab: CGPoint, retainedBonds: [UInt32]?) -> MetalPaperScene? {
        guard let marker, let window = marker.window else { return nil }
        let rect = marker.convert(marker.bounds, to: window)
        guard rect.width > 0, let scene = MetalPaperScene(image: image, seed: seed, grab: grab,
                scale: rect.width / Metrics.pageW, retainedBonds: retainedBonds,
                canvas: window.bounds.size, sheetOrigin: rect.origin) else { return nil }
        let view = scene.view
        view.frame = window.bounds
        view.accessibilityElementsHidden = true
        window.addSubview(view)
        scene.start { view.removeFromSuperview() }
        return scene
    }
}

private struct PaperAnchorView: UIViewRepresentable {
    let anchor: MobilePaperAnchor

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        anchor.marker = view
        return view
    }

    func updateUIView(_ view: UIView, context: Context) { anchor.marker = view }
}
