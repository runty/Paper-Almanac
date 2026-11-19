import AppKit
import SwiftUI
import WidgetKit

@main
enum DailyApplication {
    @MainActor static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { application.run() }
    }
}

private enum CalendarSize: Int, CaseIterable {
    case standard = 100, larger = 130, largest = 150

    static let preference = "desktopCalendarSize"
    static var saved: Self { Self(rawValue: UserDefaults.standard.integer(forKey: preference)) ?? .standard }
    var scale: CGFloat { CGFloat(rawValue) / 100 }
    var windowSize: CGSize {
        CGSize(width: Metrics.windowW + Metrics.pageW * (scale - 1),
               height: Metrics.windowH + (Metrics.blockTopPad + Metrics.pageH + 54) * (scale - 1))
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var pad: PaperWindow!
    private var host: PassThroughHostingView!
    private var item: NSStatusItem!
    private var aboutWindow: NSWindow?
    private var jumpWindow: NSWindow?
    private let store = PadStore.shared
    func applicationDidFinishLaunching(_ notification: Notification) {
        let size = CalendarSize.saved
        let rect = NSRect(origin: .zero, size: size.windowSize)
        pad = PaperWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        pad.isOpaque = false
        pad.backgroundColor = .clear
        pad.hasShadow = false
        pad.isReleasedWhenClosed = false
        pad.title = AppIdentity.name
        host = PassThroughHostingView(rootView: ContentView(store: store, pageScale: size.scale))
        host.sizingOptions = []
        pad.contentView = host
        pad.collectionBehavior = [.canJoinAllSpaces]
        if !pad.setFrameUsingName("TungShingDailyPad"), let screen = NSScreen.main {
            pad.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - rect.width, y: screen.visibleFrame.maxY - rect.height))
        }
        resizePad(to: size)
        pad.setFrameAutosaveName("TungShingDailyPad")
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateMenuBarDate()
        let menu = makeMenu()
        item.menu = menu
        let main = NSMenu()
        let entry = NSMenuItem()
        main.addItem(entry)
        entry.submenu = makeMenu()
        NSApp.mainMenu = main
        let center = NotificationCenter.default
        for name in [Notification.Name.NSCalendarDayChanged, NSApplication.didBecomeActiveNotification] {
            center.addObserver(self, selector: #selector(refresh), name: name, object: nil)
        }
        for name in [Notification.Name.NSSystemTimeZoneDidChange, .NSSystemClockDidChange] {
            center.addObserver(self, selector: #selector(clockChanged), name: name, object: nil)
        }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
        WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget")
        showPad()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showPad(); return true }
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { _ = store.openDay(url) }
        if pad != nil { showPad() }
    }
    private func makeMenu() -> NSMenu {
        let menu = NSMenu(title: AppIdentity.name)
        func action(_ name: String, _ selector: Selector, _ key: String = "") {
            menu.addItem(withTitle: name, action: selector, keyEquivalent: key).target = self
        }
        action("Today", #selector(today), "t")
        action("Go to Date…", #selector(jump), "l")
        let themes = NSMenu(title: "Theme")
        themes.delegate = self
        for theme in DailyTheme.allCases {
            let option = themes.addItem(withTitle: theme.title, action: #selector(selectTheme(_:)), keyEquivalent: "")
            option.target = self
            option.representedObject = theme.rawValue
        }
        let chooser = menu.addItem(withTitle: "Theme", action: nil, keyEquivalent: "")
        chooser.submenu = themes
        let sizes = NSMenu(title: "Calendar Size")
        sizes.delegate = self
        for size in CalendarSize.allCases {
            let option = sizes.addItem(withTitle: "\(size.rawValue)%", action: #selector(selectSize(_:)), keyEquivalent: "")
            option.tag = size.rawValue
            option.target = self
        }
        menu.addItem(withTitle: "Calendar Size", action: nil, keyEquivalent: "").submenu = sizes
        action("Auto Change Date", #selector(toggleAutomaticDate))
        action("Use Current Location", #selector(toggleMoonLocation))
        action("Show Month Calendar", #selector(toggleLayout))
        menu.delegate = self
        menu.addItem(.separator())
        action("About", #selector(aboutApp))
        action("Quit", #selector(quit), "q")
        return menu
    }
    func menuWillOpen(_ menu: NSMenu) {
        if menu === item?.menu { pad?.orderFrontRegardless() }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        for option in menu.items {
            if option.action == #selector(toggleAutomaticDate) {
                option.state = store.automaticallyUpdatesDate ? .on : .off
            } else if option.action == #selector(toggleMoonLocation) {
                option.isHidden = store.theme != .moon
                option.state = MoonLocation.shared.enabled ? .on : .off
            } else if option.action == #selector(toggleLayout) {
                option.isHidden = store.theme.original == nil
                option.title = store.calendarLayout ? "Show Do and Don’t" : "Show Month Calendar"
                option.image = NSImage(systemSymbolName: store.calendarLayout ? "list.bullet" : "calendar",
                                       accessibilityDescription: nil)
            } else if option.action == #selector(selectSize(_:)) {
                option.state = option.tag == CalendarSize.saved.rawValue ? .on : .off
            } else if let value = option.representedObject as? String {
                option.state = value == store.theme.rawValue ? .on : .off
            }
        }
    }
    @objc private func selectSize(_ sender: NSMenuItem) {
        guard let size = CalendarSize(rawValue: sender.tag), size != .saved else { return }
        UserDefaults.standard.set(size.rawValue, forKey: CalendarSize.preference)
        resizePad(to: size)
    }

    private func resizePad(to size: CalendarSize) {
        let scale = size.scale
        let old = pad.frame
        let screen = (pad.screen ?? NSScreen.main)?.visibleFrame
        // Keep the top of the pad anchored. Trim the transparent space below it on short screens.
        let width = size.windowSize.width
        let height = min(size.windowSize.height, screen?.height ?? .greatestFiniteMagnitude)
        var frame = NSRect(x: old.midX - width / 2, y: old.maxY - height, width: width, height: height)
        if let screen {
            frame.origin.x = max(screen.minX, min(frame.minX, screen.maxX - width))
            frame.origin.y = max(screen.minY, min(frame.minY, screen.maxY - height))
        }
        host.rootView = ContentView(store: store, pageScale: scale)
        host.interactiveRect = CGRect(x: (width - Metrics.pageW * scale) / 2 - 12 * scale,
                                      y: (store.theme.blockTopPad - 8) * scale,
                                      width: (Metrics.pageW + 24) * scale, height: (Metrics.pageH + 54) * scale)
        pad.setFrame(frame, display: true)
    }

    private func updateMenuBarDate() {
        guard let button = item?.button else { return }
        let now = Date.now
        let day = CivilDay.calendar().component(.day, from: now)
        let title = AppIdentity.name + ", " + now.formatted(date: .complete, time: .omitted)
        let image = NSImage(size: NSSize(width: 19, height: 19), flipped: false) { bounds in
            NSColor.black.set()
            let page = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.8, dy: 0.8), xRadius: 3, yRadius: 3)
            page.lineWidth = 1.4
            page.stroke()
            page.addClip()
            NSBezierPath(rect: NSRect(x: 0, y: 14.4, width: 19, height: 4)).fill()
            let number = NSAttributedString(string: String(day), attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold),
                .foregroundColor: NSColor.black
            ])
            let size = number.size()
            number.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (15 - size.height) / 2))
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = title
        button.image = image
        button.setAccessibilityIdentifier(AppIdentity.name)
        button.toolTip = title
    }

    @objc private func refresh() {
        if store.theme == .moon { MoonLocation.shared.refresh() }
        store.refreshToday()
        updateMenuBarDate()
    }
    @objc private func clockChanged() {
        refresh()
        WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget")
    }
    private func showPad() { pad?.makeKeyAndOrderFront(nil); NSApp.activate() }
    @objc private func toggleAutomaticDate() {
        store.setAutomaticallyUpdatesDate(!store.automaticallyUpdatesDate)
    }
    @objc private func toggleMoonLocation() {
        MoonLocation.shared.setEnabled(!MoonLocation.shared.enabled)
    }
    @objc private func today() { store.today(); showPad() }
    @objc private func aboutApp() {
        if aboutWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 470, height: 570),
                                  styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            window.title = "About"
            window.titleVisibility = .hidden
            window.contentMinSize = NSSize(width: 320, height: 260)
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: AboutAlmanac())
            window.center()
            aboutWindow = window
        }
        NSApp.activate()
        aboutWindow?.makeKeyAndOrderFront(nil)
    }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func toggleLayout() {
        store.calendarLayout.toggle()
        DailyTheme.defaults.set(store.calendarLayout, forKey: DailyTheme.calendarLayoutKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget")
    }
    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String,
              let theme = DailyTheme(rawValue: value), theme != store.theme else { return }
        store.calendarLayout = theme.opensWithCalendar
        DailyTheme.defaults.set(store.calendarLayout, forKey: DailyTheme.calendarLayoutKey)
        DailyTheme.defaults.set(value, forKey: DailyTheme.key)
        let movesPage = store.theme.blockTopPad != theme.blockTopPad
        store.theme = theme
        if movesPage { resizePad(to: .saved) }
        if theme == .moon { MoonLocation.shared.refresh() }
        WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget")
    }
    @objc private func jump() {
        if let window = jumpWindow { window.close() }
        let window = NSWindow(contentRect: .init(x: 0,y: 0,width: 280,height: 110), styleMask: [.titled,.closable], backing: .buffered, defer: false)
        window.title = "Go to Date"
        window.isReleasedWhenClosed = false
        let formatter = DateFormatter()
        formatter.calendar = CivilDay.calendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        window.contentView = NSHostingView(rootView: JumpPicker(date: formatter.date(from: store.top.label) ?? .now,
            range: formatter.date(from: "1901-01-01")!...formatter.date(from: "2100-12-31")!) { [weak window] date in
            self.store.browse(CivilDay.label(date)); window?.close(); self.showPad()
        })
        jumpWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}
private struct JumpPicker: View {
    @State var date: Date
    let range: ClosedRange<Date>
    let select: (Date) -> Void
    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            DatePicker("Date", selection: $date, in: range, displayedComponents: .date)
                .environment(\.calendar, CivilDay.calendar())
            Button("Show Day") { select(date) }.keyboardShortcut(.defaultAction)
        }.padding()
    }
}
