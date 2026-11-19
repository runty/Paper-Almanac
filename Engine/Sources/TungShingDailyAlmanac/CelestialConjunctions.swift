import CryptoKit
import Foundation
import TungShingCore

/// Only millisecond-rounded conjunction roots are bundled, not an astronomical ephemeris.
struct CelestialConjunctions: Sendable {
    static let algorithmRevision = "celestial-elapsed-moon-age-2"
    static let resourceSHA256 = "9abaf747539299e3cda06cbdd04d4b040108ecd743f45bf24b535ae5a34f22bf"
    private static let millisecondsPerDay: Int64 = 86_400_000
    private let timestamps: [Int64]

    static let bundled: Self? = DailyAlmanacResources.data("celestial-conjunctions").flatMap(Self.init(data:))

    init?(data: Data) {
        guard SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == Self.resourceSHA256,
              let document = try? JSONDecoder().decode(Document.self, from: data),
              document.schema == "celestial-conjunctions-1",
              document.eventModel == "DE440S-SKYFIELD155-SCALAR-REAL-v1",
              document.epoch == "J2000.0 TT", document.unit == "millisecond",
              document.conjunctions.count == 2476,
              let first = document.conjunctions.first, let last = document.conjunctions.last,
              first <= Self.sampleMilliseconds(DailyAlmanacReader.firstDate),
              last > Self.sampleMilliseconds(DailyAlmanacReader.lastDate),
              zip(document.conjunctions, document.conjunctions.dropFirst()).allSatisfy({
                  let spacing = $1 - $0
                  return spacing > 29 * Self.millisecondsPerDay && spacing < 30 * Self.millisecondsPerDay
              }) else { return nil }
        timestamps = document.conjunctions
    }

    func elapsedDays(at date: GregorianDate) -> Double? {
        let sample = Self.sampleMilliseconds(date)
        guard let first = timestamps.first, let last = timestamps.last, first <= sample, sample < last else { return nil }
        var lower = 0, upper = timestamps.count
        while lower < upper {
            let middle = (lower + upper) / 2
            if timestamps[middle] <= sample { lower = middle + 1 } else { upper = middle }
        }
        return Double(sample - timestamps[lower - 1]) / Double(Self.millisecondsPerDay)
    }

    private static func sampleMilliseconds(_ date: GregorianDate) -> Int64 {
        // J2000.0 = 2000-01-01 12:00 TT. The date's 12:00 frozen reference UTC is
        // 12:01:09.184 TT; dayID 10957 is 2000-01-01. Every operation before division is exact.
        (date.dayID.value - 10_957) * millisecondsPerDay + 69_184
    }

    private struct Document: Decodable {
        let schema: String
        let eventModel: String
        let epoch: String
        let unit: String
        let conjunctions: [Int64]
    }
}
