import Foundation
import TungShingCore

struct ChineseProverb: Equatable {
    let headword: String
    let english: String

    private final class ResourceBundle {}

    static let entries: [ChineseProverb] = {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: ResourceBundle.self)
        #endif
        guard let url = bundle.url(forResource: "ChineseProverbs", withExtension: "tsv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.split(whereSeparator: \.isNewline).compactMap { line in
            guard !line.hasPrefix("#") else { return nil }
            let fields = line.split(separator: "\t")
            guard fields.count == 2 else { return nil }
            return ChineseProverb(headword: String(fields[0]), english: String(fields[1]))
        }
    }()

    static func on(_ date: GregorianDate) -> ChineseProverb? {
        guard !entries.isEmpty else { return nil }
        let monday = date.dayID.value - Int64((date.weekdaySunday0 + 6) % 7)
        // Day 4 is Monday, January 5, 1970. Wrap earlier weeks through the same edition.
        let week = (monday - 4) / 7
        let count = Int64(entries.count)
        return entries[Int((week % count + count) % count)]
    }
}
