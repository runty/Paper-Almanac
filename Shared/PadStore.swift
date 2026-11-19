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
    private var dates: PadDates
    private var fetching: Task<Void, Never>?
    private var midnight: Timer?
    private var cache: [String: PrintedDay] = [:]
    static let advanceKey = "pad.advancedCivilDay"
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let state = PadDates(today: CivilDay.label(), advance: defaults.string(forKey: Self.advanceKey))
        dates = state
        top = Sheet(label: state.visible, loading: true)
        next = Sheet(label: state.visible, loading: true)
        show()
        scheduleMidnight()
    }
    var canTear: Bool { CivilDay.step(top.label, 1) == next.label && next.page != nil && top.page != nil }
    var remainingFraction: Double {
        CivilDay.remainingPaper(on: top.label)
    }
    func refreshToday() {
        let previous = dates.visible
        dates.refresh(CivilDay.label(), persistedAdvance: defaults.string(forKey: Self.advanceKey))
        if dates.visible != previous || (!top.loading && top.page == nil) { show() }
        saveAdvance()
        scheduleMidnight()
    }
    func tear() {
        guard canTear else { return }
        tornCount += 1
        dates.tear()
        saveAdvance()
        show()
    }
    func browse(_ label: String) { dates.browse(label); show() }
    func openDay(_ url: URL) -> Bool {
        guard url.scheme == "tungshingdaily", url.host == "day",
              CivilDay.step(url.lastPathComponent, 0) != nil else { return false }
        browse(url.lastPathComponent)
        let side = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .first { $0.name == "activities" }?.value
        activitySide = side.flatMap(ActivityPreference.Side.init(rawValue:))
        return true
    }
    func step(_ delta: Int) { if let day = CivilDay.step(dates.visible, delta) { browse(day) } }
    func today() { dates.refresh(CivilDay.label()); dates.returnToToday(); saveAdvance(); show() }
    private func saveAdvance() {
        if defaults.string(forKey: Self.advanceKey) != dates.advance {
            defaults.set(dates.advance, forKey: Self.advanceKey)
        }
    }
    private func scheduleMidnight() {
        midnight?.invalidate()
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
