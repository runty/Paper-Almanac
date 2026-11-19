import Foundation
import TungShingAlmanac

/// Civil typography for the original Himekuri layouts. All almanac values come from the same printed report.
struct DayInfo {
    let page: PrintedDay
    var calendarLayout = false

    var grid: [[Int?]] {
        let days = CivilDay.calendar().range(of: .day, in: .month, for: date)!
        let leading = (weekday - 1 - (day - 1) % 7 + 7) % 7
        return stride(from: 0, to: leading + days.count, by: 7).map { start in
            (0..<7).map { column in
                let number = start + column - leading + 1
                return days.contains(number) ? number : nil
            }
        }
    }

    var proverb: (jp: String, en: String) { Proverbs.on(dayID: page.date.dayID.value) }
    func calendarProverb(for theme: PageTheme) -> String? {
        switch theme {
        case .showa: proverb.jp + " · " + proverb.en
        case .koyomi: proverb.jp
        default: nil
        }
    }
    var eraYear: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.dateFormat = "GGGGy年"
        return formatter.string(from: date)
    }
    var rokuyo: String { ["大安", "赤口", "先勝", "友引", "先負", "仏滅"][(lunarMonth + lunarDay) % 6] }

    var report: AlmanacDayReport { page.report }
    var year: Int { Int(page.date.year) }
    var month: Int { Int(page.date.month) }
    var day: Int { Int(page.date.day) }
    var weekday: Int { page.date.weekdaySunday0 + 1 }
    var isSunday: Bool { weekday == 1 }
    var isSaturday: Bool { weekday == 7 }
    var date: Date { CivilDay.calendar().date(from: DateComponents(year: year, month: month, day: day, hour: 12))! }
    var dayOfYear: Int { CivilDay.calendar().ordinality(of: .day, in: .year, for: date)! }
    var weekOfYear: Int { CivilDay.calendar().component(.weekOfYear, from: date) }
    var weekdayEN: String { String(weekdayNamesEN[weekday].prefix(3)) }
    var weekdayKanji: String { Array("日月火水木金土").map(String.init)[weekday-1] + "曜日" }
    var lunarMonth: Int { Int(report.lunar.month) }
    var lunarDay: Int { Int(report.lunar.day) }
    var isLeapLunarMonth: Bool { report.lunar.isLeapMonth }
    var lunarCaption: String { report.lunarMonthLabel + report.lunarDayLabel }
    var yearPillar: String { report.yearPillar.label + "年" }
    func chineseActivities(_ reading: Reading, empty: String) -> [String] {
        reading.tokens.isEmpty ? (reading.lines == ["No activities to show"] ? ["—"] : [empty]) : reading.tokens.map { $0.applyingTransform(StringTransform("Simplified-Traditional"), reverse: false) ?? $0 }
    }
}

import TungShingData
let hourBranches = Array("子丑寅卯辰巳午未申酉戌亥").map(String.init)
func termName(_ term: SolarTermDate) -> String { Calendar2100Provider.termNames[Int(term.indexFromMarchEquinox)] }
extension DayInfo {
    var phase: String? { report.moonPhase == .none ? nil : report.moonPhase.rawValue }
}
