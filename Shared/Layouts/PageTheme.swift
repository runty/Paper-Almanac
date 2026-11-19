//
//  PageTheme.swift
//  himekuri
//
//  Print styles for the pad. Each theme is a palette + a page layout;
//  the paper object itself (binding, stack, tear) stays the same.
//

import SwiftUI

nonisolated enum PageTheme {
    case showa
    case koyomi
    case huangli
    case tongsheng

    var title: String {
        switch self {
        case .showa: String(localized: "Shōwa Print")
        case .koyomi: String(localized: "Koyomi")
        case .huangli: String(localized: "Huangli")
        case .tongsheng: String(localized: "Tong Sheng")
        }
    }

    var paper: Color {
        switch self {
        case .showa: Color(red: 0.978, green: 0.972, blue: 0.948) // thin white stock
        case .koyomi: Color(red: 0.949, green: 0.914, blue: 0.827)
        case .huangli: Color(red: 0.985, green: 0.982, blue: 0.972) // white almanac stock
        case .tongsheng: Color(red: 0.988, green: 0.980, blue: 0.968) // cheap white newsprint
        }
    }

    var edge: Color {
        switch self {
        case .showa: Color(red: 0.905, green: 0.885, blue: 0.835)
        case .koyomi: Color(red: 0.86, green: 0.81, blue: 0.70)
        case .huangli: Color(red: 0.88, green: 0.89, blue: 0.86)
        case .tongsheng: Color(red: 0.91, green: 0.86, blue: 0.85)
        }
    }

    var ink: Color {
        switch self {
        case .showa: Color(red: 0.10, green: 0.09, blue: 0.10)
        case .koyomi: Color(red: 0.149, green: 0.129, blue: 0.110) // sumi
        case .huangli: Color(red: 0.086, green: 0.514, blue: 0.286) // old-almanac green
        case .tongsheng: Color(red: 0.792, green: 0.114, blue: 0.129) // the only ink on the press
        }
    }

    var sunday: Color {
        switch self {
        case .showa: Color(red: 0.82, green: 0.22, blue: 0.13)
        case .koyomi: Color(red: 0.776, green: 0.227, blue: 0.129)
        case .huangli: Color(red: 0.086, green: 0.514, blue: 0.286) // one ink here too
        case .tongsheng: Color(red: 0.792, green: 0.114, blue: 0.129) // one ink: no redder Sunday
        }
    }

    var saturday: Color {
        switch self {
        case .showa: Color(red: 0.18, green: 0.29, blue: 0.55)
        case .koyomi: Color(red: 0.227, green: 0.353, blue: 0.549)
        case .huangli: Color(red: 0.086, green: 0.514, blue: 0.286) // …and no jade Saturday
        case .tongsheng: Color(red: 0.792, green: 0.114, blue: 0.129) // …and no blue Saturday
        }
    }

    /// The red used for rules, seals, boxes — independent of the weekday.
    var accentRed: Color { sunday }

    var grainStrength: Double {
        switch self {
        case .showa: 0.8
        case .koyomi: 1.35
        case .huangli: 1.1
        case .tongsheng: 1.3
        }
    }

    /// How solid the paper is. The two almanac pages are printed on stock thin
    /// enough to hint at the desk behind them — 1 is opaque, and only the paper
    /// fades: the ink stays at full strength so the page is still legible over
    /// a busy desktop. Kept high on purpose; further down and the page stops
    /// reading as paper and starts reading as a bug.
    var paperOpacity: Double {
        switch self {
        case .huangli, .tongsheng: 0.88
        default: 1
        }
    }

    func accent(for info: DayInfo) -> Color {
        info.isSunday ? sunday : info.isSaturday ? saturday : ink
    }
}

/// Kanji numerals for the traditional themes (1–31, months 1–12).
nonisolated func kanjiNumber(_ n: Int) -> String {
    let digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    switch n {
    case 1...10: return digits[n]
    case 11...19: return "十" + digits[n - 10]
    case 20: return "二十"
    case 21...29: return "二十" + digits[n - 20]
    case 30: return "三十"
    case 31: return "三十一"
    default: return "\(n)"
    }
}
