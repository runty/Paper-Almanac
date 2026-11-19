import SwiftUI

@MainActor
final class PadStore: ObservableObject {
    static let shared = PadStore()
    @Published private(set) var top: Sheet
    @Published private(set) var next: Sheet
    @Published private(set) var tornCount = 0
    @Published var activitySide: ActivityPreference.Side?
    @Published var calendarLayout = DailyTheme.savedCalendarLayout
    @Published var theme = DailyTheme.current
    @Published private var dates: PadDates
    private var fetching: Task<Void, Never>?
    private var midnight: Timer?
    private var cache: [String: PrintedDay] = [:]
    static let advanceKey = "pad.advancedCivilDay"
    static let heldDayKey = "pad.heldCivilDay"
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let state = PadDates(today: CivilDay.label(), advance: defaults.string(forKey: Self.advanceKey),
                             heldDay: defaults.string(forKey: Self.heldDayKey))
        dates = state
        top = Sheet(label: state.visible, loading: true)
        next = Sheet(label: state.visible, loading: true)
        show()
        scheduleMidnight()
    }
    var automaticallyUpdatesDate: Bool { dates.automaticallyUpdatesDate }
    var canTear: Bool { CivilDay.step(top.label, 1) == next.label && next.page != nil && top.page != nil }
    var remainingFraction: Double {
        CivilDay.remainingPaper(on: top.label)
    }
    func updateSkySite(_ site: SkySite?) {
        if top.skySite != site { top.skySite = site }
        if next.skySite != site { next.skySite = site }
    }

    func refreshToday() {
        let previous = dates.visible
        readDates()
        if dates.visible != previous || (!top.loading && top.page == nil) { show() }
        saveDates()
        scheduleMidnight()
    }
    func tear() {
        guard canTear else { return }
        tornCount += 1
        dates.tear()
        saveDates()
        show()
    }
    func browse(_ label: String) { dates.browse(label); show() }
    func openDay(_ url: URL) -> Bool {
        guard url.scheme == "tungshingdaily", url.host == "day",
              CivilDay.step(url.lastPathComponent, 0) != nil else { return false }
        browse(url.lastPathComponent)
        activitySide = nil
        return true
    }
    func step(_ delta: Int) { if let day = CivilDay.step(dates.visible, delta) { browse(day) } }
    func today() {
        readDates()
        dates.returnToToday()
        saveDates()
        show()
    }

    func setAutomaticallyUpdatesDate(_ enabled: Bool) {
        let previous = dates.visible
        readDates()
        dates.setAutomaticallyUpdatesDate(enabled)
        saveDates()
        scheduleMidnight()
        if dates.visible != previous { show() }
    }

    private func readDates() {
        dates.refresh(CivilDay.label(), persistedAdvance: defaults.string(forKey: Self.advanceKey),
                      persistedHeldDay: defaults.string(forKey: Self.heldDayKey))
    }

    private func saveDates() {
        if defaults.string(forKey: Self.advanceKey) != dates.advance {
            defaults.set(dates.advance, forKey: Self.advanceKey)
        }
        if defaults.string(forKey: Self.heldDayKey) != dates.heldDay {
            defaults.set(dates.heldDay, forKey: Self.heldDayKey)
        }
    }

    private func scheduleMidnight() {
        midnight?.invalidate()
        midnight = nil
        guard automaticallyUpdatesDate else { return }
        let timer = Timer(fire: CivilDay.nextMidnight(after: .now), interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.refreshToday() }
        }
        RunLoop.main.add(timer, forMode: .common)
        midnight = timer
    }
    private func show() {
        fetching?.cancel()
        let label = dates.visible
        if top.label != label { activitySide = nil }
        let tomorrow = CivilDay.step(label, 1)
        func sheet(_ key: String) -> Sheet { Sheet(label: key, page: cache[key], loading: cache[key] == nil && CivilDay.range.contains(key)) }
        top = sheet(label)
        next = sheet(tomorrow ?? label)
        fetching = Task {
            for key in [label, tomorrow].compactMap({ $0 }) where CivilDay.range.contains(key) {
                guard !Task.isCancelled else { return }
                let result: PrintedDay?
                if let cached = cache[key] { result = cached } else { result = try? await DayReader.load([key]).first }
                guard !Task.isCancelled else { return }
                if let result {
                    if cache.count > 31 { cache.removeAll(keepingCapacity: true) }
                    cache[key] = result
                }
                let sheet = Sheet(label: key, page: result)
                if top.label == key { top = sheet }
                if next.label == key { next = sheet }
            }
        }
    }
}
