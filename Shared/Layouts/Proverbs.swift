//
//  Proverbs.swift
//  himekuri
//
//  The original Himekuri sayings and the expanded Japanese print edition.
//

import Foundation

nonisolated enum Proverbs {
    private final class ResourceBundle {}
    private static let originals: [(jp: String, en: String)] = [
        ("七転び八起き", "Fall seven times, rise eight."),
        ("塵も積もれば山となる", "Even dust, piled up, becomes a mountain."),
        ("継続は力なり", "Persistence is power."),
        ("明日は明日の風が吹く", "Tomorrow, tomorrow's wind will blow."),
        ("石の上にも三年", "Three years sitting on a stone."),
        ("花より団子", "Dumplings over flowers."),
        ("一期一会", "One time, one meeting."),
        ("猿も木から落ちる", "Even monkeys fall from trees."),
        ("急がば回れ", "When in a hurry, take the long way round."),
        ("初心忘るべからず", "Never forget the beginner's spirit."),
        ("案ずるより産むが易し", "Doing is easier than fearing."),
        ("笑う門には福来る", "Fortune visits a laughing gate."),
        ("千里の道も一歩から", "A thousand-mile road starts with one step."),
        ("温故知新", "Study the old to know the new."),
        ("雨降って地固まる", "After the rain, the earth hardens."),
        ("井の中の蛙大海を知らず", "A frog in a well knows not the ocean."),
    ]

    static let all: [(jp: String, en: String)] = {
        guard let url = Bundle(for: ResourceBundle.self).url(forResource: "JapaneseProverbs", withExtension: "tsv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return originals }
        return originals + text.split(whereSeparator: \.isNewline).compactMap { line in
            guard !line.hasPrefix("#") else { return nil }
            let fields = line.split(separator: "\t")
            guard fields.count == 2 else { return nil }
            return (String(fields[0]), String(fields[1]))
        }
    }()

    static func on(dayID: Int64) -> (jp: String, en: String) {
        let count = Int64(all.count)
        return all[Int((dayID % count + count) % count)]
    }
}
