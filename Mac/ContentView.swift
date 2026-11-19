import SwiftUI

struct ContentView: View {
    @ObservedObject var store = PadStore.shared
    @ObservedObject private var location = MoonLocation.shared
    var pageScale: CGFloat = 1
    private var theme: PageTheme { store.theme.original ?? .tongsheng }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            padBlock
                .scaleEffect(pageScale, anchor: .top)
                .padding(.top, Metrics.blockTopPad * pageScale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            store.refreshToday()
            if store.theme == .moon { location.refresh() }
        }
        .onReceive(location.$site) { store.updateSkySite($0) }
        .alert("Sky Notes", isPresented: Binding(get: { location.message != nil }, set: { if !$0 { location.message = nil } })) {
            Button("OK") { location.message = nil }
        } message: { Text(location.message ?? "") }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(store.top.description(for: store.theme, calendarLayout: store.calendarLayout))
        .accessibilityIdentifier("daily-sheet-" + store.top.label + (store.top.page == nil ? "-pending" : ""))
        .accessibilityValue(store.top.label)
        .accessibilityAction(named: "Tear to next day") { store.tear() }
        .accessibilityAction(named: "Today") { store.today() }
        .activityListActions(store: store, enabled: store.theme != .fuji && store.theme != .moon)
        .activityLists(store: store, theme: store.theme)
    }

    // MARK: - The pad

    private var padBlock: some View {
        let remaining = store.remainingFraction
        return ZStack(alignment: .top) {
            // Soft shadow the whole object casts on the wall.
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.30 * theme.paperOpacity))
                .frame(width: Metrics.pageW, height: Metrics.pageH)
                .offset(x: 2 + 4 * remaining, y: Metrics.pageTopInset + 2 + 12 * remaining)
                .blur(radius: 3 + 13 * remaining)

            if store.theme == .fuji {
                FujiPaperStack(remainingFraction: remaining)
            } else {
                PadStack(remainingFraction: remaining, theme: theme)
            }

            SheetView(sheet: store.next, theme: store.theme, calendarLayout: store.calendarLayout)
                // Recessed in the stack and shaded by the sheet above: without
                // this the revealed page reads as a bright copy of the top one.
                .overlay(
                    LinearGradient(stops: [
                        .init(color: .black.opacity(0.11), location: 0),
                        .init(color: .black.opacity(0.05), location: 0.45),
                        .init(color: .black.opacity(0.08), location: 1),
                    ], startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)
                )
                .allowsHitTesting(false)
                .padding(.top, Metrics.pageTopInset)

            DesktopTearSheet(store: store, scale: pageScale)
                .id(DesktopTearSheet.Identity(day: store.top.label, theme: store.theme,
                                              calendarLayout: store.calendarLayout, scale: pageScale))
                .padding(.top, Metrics.pageTopInset)

            if store.tornCount > 0 {
                PadStubs(tornCount: store.tornCount, theme: theme)
                    .padding(.top, Metrics.pageTopInset)
            }

            ThemeBinding(theme: store.theme)
        }
        .frame(
            width: Metrics.pageW + 2 * Metrics.overhangX,
            height: Metrics.pageH + 60,
            alignment: .top
        )
    }
}
