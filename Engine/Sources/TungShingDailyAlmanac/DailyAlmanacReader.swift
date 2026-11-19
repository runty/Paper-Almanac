// A deliberately finite daily consumer of the admitted calendar/almanac pair.
// Calculation code remains in Calendar2100Provider and AlmanacEvaluator.

import Foundation
@_exported import TungShingAlmanac
@_exported import TungShingCore
import TungShingData

public enum DailyAlmanacUnavailable: Error, Sendable, Hashable {
    case outsideSupportedDomain
    case invalidResources(Calendar2100Provider.LoadError)
    case invalidContext(AlmanacContextError)
    case evaluation(AlmanacEvaluationError)
    case identityFailure
}

/// A source comparison explains a difference; it never changes the model's result.
public enum DailyAlmanacSourceComparison: String, Sendable, Hashable {
    case agrees
    case differsCalendarInput = "differs-calendar-input"
    case differsDependencyInput = "differs-dependency-input"
    case sourceUnavailable = "source-unavailable"
}

public struct DailyAlmanacDay: Sendable, Hashable {
    /// Identity of this daily calculation. This API has its own identity namespace; it is not an
    /// Engine CalendarDaySnapshot/AlmanacDaySnapshot identity. Theme and localization are excluded.
    public let identity: ResultID
    public let report: AlmanacDayReport
    /// Includes lunar leap identity, HKO comparison and the model's boundary-sensitivity disclosures.
    public let calendar: Calendar2100Provider.Day
    public let sourceComparison: DailyAlmanacSourceComparison
    public var date: GregorianDate { calendar.date }
    public var weekday: Weekday { date.weekday }
    public var currentOrNextTerm: TungShingAlmanac.SolarTermDate { report.termOnDate ?? report.nextTerm }
}

public enum DailyAlmanacOutcome: Sendable, Hashable {
    case ready(DailyAlmanacDay)
    case unavailable(DailyAlmanacUnavailable)
}

/// Offline and immutable. The caller supplies civil components explicitly; no clock, locale,
/// device time zone, network, saved calendar, birthday or consultation participates in the result.
/// The only offered pair is fixed +08:00 / frozen K=37, with the corrected noon almanac.
public struct DailyAlmanacReader: Sendable {
    public static let firstDate = try! GregorianDate(year: 1901, month: 1, day: 1)
    public static let lastDate = try! GregorianDate(year: 2100, month: 12, day: 31)
    public static let calendarProfile = try! ProfileID(Calendar2100Provider.profile)
    public static let almanacProfile = AlmanacProfile.calendar2100Corrected
    public static let fixedOffsetSeconds = 28_800
    public static let algorithmRevision = "daily-almanac-1"

    private let resources: Result<DailyAlmanacResources, Calendar2100Provider.LoadError>

    private init(resources: Result<DailyAlmanacResources, Calendar2100Provider.LoadError>) {
        self.resources = resources
    }

    /// Resources are authenticated once and shared as immutable values. Failure remains an outcome
    /// of `day(for:)`, so an app can still print the requested Gregorian date.
    public static func bundled() -> DailyAlmanacReader { Self(resources: DailyAlmanacResources.bundled) }

    /// The full upstream MIT attribution/license for an application's acknowledgements screen.
    public static var thirdPartyNotices: String {
        DailyAlmanacResources.notice
    }

    /// Executes away from a calling UI actor. Cancellation throws CancellationError, separately
    /// from an unavailable almanac. No alternate profile or Foundation Chinese-calendar fallback.
    @concurrent public func day(for date: GregorianDate) async throws -> DailyAlmanacOutcome {
        try Task.checkCancellation()
        guard Self.firstDate <= date, date <= Self.lastDate else { return .unavailable(.outsideSupportedDomain) }
        let resources: DailyAlmanacResources
        switch self.resources {
        case .success(let value): resources = value
        case .failure(let error): return .unavailable(.invalidResources(error))
        }
        let calendar = resources.provider.facts(date)
        let context: AlmanacDayContext
        do {
            let lunar = try LunarDate(lunarYearStartingGregorianYear: calendar.lunarYear, month: calendar.month,
                                      isLeapMonth: calendar.isLeap, day: calendar.day)
            // Match the engine's 80-day dependency window, with the nearest surrounding witnesses.
            let lower = try date.adding(days: -80), upper = try date.adding(days: 81)
            let terms = resources.terms.filter { lower <= $0.date && $0.date < upper }
            context = try AlmanacDayContext(gregorian: date, lunar: lunar, lunarMonthLength: calendar.monthLength,
                                            evaluationHour: Self.almanacProfile.evaluationHour, solarTerms: terms)
        } catch let error as AlmanacContextError { return .unavailable(.invalidContext(error)) }
        catch { return .unavailable(.invalidResources(.malformed("calendar context"))) }
        let report: AlmanacDayReport
        do { report = try AlmanacEvaluator.evaluate(context, profile: Self.almanacProfile) }
        catch { return .unavailable(.evaluation(error)) }
        try Task.checkCancellation()
        let comparison = resources.comparisons[date] ?? .agrees
        // All calculation-changing inputs are pinned. Retain output witnesses as well as input identity.
        guard let identity = try? ResultID(digest: CanonicalJSON.digest(role: .result, value: .object([
            "kind": .string("dailyAlmanacDay"), "algorithmRevision": .string(Self.algorithmRevision),
            "date": .string(date.label), "calendarProfile": .string(Self.calendarProfile.value),
            "runtimeSHA256": .string(DailyAlmanacResources.runtimeSHA256),
            "contextSHA256": .string(DailyAlmanacResources.contextSHA256),
            "differencesSHA256": .string(DailyAlmanacResources.differencesSHA256),
            "profile": .string(report.profile.value), "profileDigest": .string(report.profileDigest),
            "portRevision": .string(Self.almanacProfile.portRevision),
            "sourceComparison": .string(comparison.rawValue),
            "recommendations": .array(report.recommendations.map { .string($0.rawValue) }),
            "avoidances": .array(report.avoidances.map { .string($0.rawValue) }),
        ]))) else { return .unavailable(.identityFailure) }
        return .ready(DailyAlmanacDay(identity: identity, report: report, calendar: calendar, sourceComparison: comparison))
    }

    // Explicitly untrusted bytes are used only by this target's corruption tests.
    init(runtime: Data, context: Data, differences: Data) {
        do { self.init(resources: .success(try DailyAlmanacResources(runtime: runtime, context: context, differences: differences))) }
        catch { self.init(resources: .failure(error)) }
    }
}
