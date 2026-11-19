import Foundation
import TungShingAlmanac
import TungShingCore
import TungShingDailyAlmanac

struct Reading {
    let allLines: [String]
    var lines: [String] { Array(allLines.prefix(4)) }
    var remaining: Int { max(0, allLines.count - 4) }
    var tokens: [String] = []
}

struct PrintedDay {
    let report: AlmanacDayReport
    let recommended: Reading
    let avoided: Reading

    var date: GregorianDate { report.gregorian }
    var holiday: (chinese: String, english: String)? {
        if date.month == 11 && date.day == 11 { return ("光棍節", "Singles’ Day") }
        let lunar = report.lunar
        if !lunar.isLeapMonth {
            switch (lunar.month, lunar.day) {
            case (1, 1): return ("春節", "Lunar New Year")
            case (5, 5): return ("端午節", "Dragon Boat Festival")
            case (8, 15): return ("中秋節", "Mid-Autumn Festival")
            default: break
            }
        }
        if report.termOnDate?.indexFromMarchEquinox == 1 { return ("清明", "Ching Ming") }
        switch (date.month, date.day) {
        case (1, 1): return ("元旦", "New Year’s Day")
        case (5, 1): return ("勞動節", "Labour Day")
        case (10, 1): return ("國慶日", "National Day")
        case (12, 25): return ("聖誕節", "Christmas Day")
        default: return nil
        }
    }

    init(report: AlmanacDayReport) {
        self.report = report
        func ranked(_ list: [AlmanacActivity], side: ActivityPreference.Side) -> [String] {
            ActivityPreference.rank(list.filter { !$0.isSentinel }.map(\.rawValue),
                                    date: report.gregorian.label, side: side)
        }
        func reading(_ values: [String], empty: String) -> Reading {
            let labels = values.map { ActivityPreference.labels[$0] ?? ActivityGlosses.table[$0] ?? $0 }
            return Reading(allLines: labels.isEmpty ? [empty] : labels, tokens: Array(values.prefix(4)))
        }
        let good = ranked(report.recommendations, side: .recommended)
        let bad = ranked(report.avoidances, side: .avoided)
        if report.trace.avoidsEverything {
            recommended = Reading(allLines: ["Nothing recommended"])
            avoided = Reading(allLines: ["Avoid all activities"])
        } else {
            recommended = reading(good,
                                  empty: report.recommendations.contains(.nothingSuitable) ? "Nothing recommended" : report.recommendations.isEmpty ? "None listed" : "No activities to show")
            avoided = reading(bad,
                              empty: report.avoidances.contains(.nothingAvoided) ? "Nothing specifically discouraged" : report.avoidances.isEmpty ? "None listed" : "No activities to show")
        }
    }
}

enum DayReader {
    static func load(_ labels: [String]) async throws -> [PrintedDay] {
        let reader = DailyAlmanacReader.bundled()
        var pages: [PrintedDay] = []
        for label in labels {
            let date = try GregorianDate(label: label)
            switch try await reader.day(for: date) {
            case .ready(let day): pages.append(PrintedDay(report: day.report))
            case .unavailable(let reason): throw ProofError.unavailable("\(label) · \(reason)")
            }
        }
        return pages
    }
}

enum ProofError: Error {
    case unavailable(String)
}
