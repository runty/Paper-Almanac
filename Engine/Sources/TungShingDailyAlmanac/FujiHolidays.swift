import TungShingCore
import TungShingJapanHolidays

/// Japanese national holiday names from the admitted Cabinet Office table, 1955–2027.
public enum FujiHolidays {
    /// Source credit for display by consumers; nil when the admitted table is unavailable.
    public static var attribution: String? {
        attribution(using: RegionalHolidaysJP1Assets.holidays)
    }

    /// Published years, inclusive; nil when the admitted table is unavailable.
    public static var coverage: ClosedRange<Int>? {
        coverage(using: RegionalHolidaysJP1Assets.holidays)
    }

    /// The source name verbatim, including substitute/citizens' holidays and special acts.
    /// Returns nil for ordinary dates, dates outside published coverage, or unavailable resources.
    public static func name(on date: GregorianDate) -> String? {
        name(on: date, using: RegionalHolidaysJP1Assets.holidays)
    }

    static func name(on date: GregorianDate, using holidays: JapanHolidays?) -> String? {
        guard let holidays,
              case .known(let day) = holidays.day(year: Int(date.year), month: Int(date.month),
                                                  day: Int(date.day), profile: JapanHolidays.runtimeProfile) else { return nil }
        return day.holiday?.name
    }

    static func attribution(using holidays: JapanHolidays?) -> String? { holidays?.attribution }
    static func coverage(using holidays: JapanHolidays?) -> ClosedRange<Int>? { holidays?.years }
}
