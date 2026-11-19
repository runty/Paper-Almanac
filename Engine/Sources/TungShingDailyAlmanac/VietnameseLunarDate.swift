import Foundation
import TungShingCore

/// The modern Vietnamese lunisolar calendar, using UTC+7 throughout the supported range.
public struct VietnameseLunarDate: Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool

    // Each row is [civil day ID of new moon, lunar year, signed month].
    private static let months: [[Int]]? = DailyAlmanacResources.data("vietnamese-months").flatMap {
        guard let rows = try? JSONDecoder().decode([[Int]].self, from: $0),
              rows.allSatisfy({ $0.count == 3 && (1...12).contains(abs($0[2])) }) else { return nil }
        return rows
    }

    public init?(on date: GregorianDate) {
        guard DailyAlmanacReader.firstDate <= date, date <= DailyAlmanacReader.lastDate,
              let months = Self.months else { return nil }
        let id = Int(date.dayID.value)
        var low = 0, high = months.count
        while low < high {
            let mid = (low + high) / 2
            if months[mid][0] <= id { low = mid + 1 } else { high = mid }
        }
        guard low > 0 else { return nil }
        let row = months[low - 1]
        year = row[1]
        month = abs(row[2])
        day = id - row[0] + 1
        isLeapMonth = row[2] < 0
    }
}
