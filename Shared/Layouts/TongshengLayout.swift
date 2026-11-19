//
//  TongshengLayout.swift
//  himekuri
//
//  通勝 — the red-ink tear-off almanac sold at every corner shop from Hong
//  Kong to Kuala Lumpur. Red on cheap white stock, a masthead in three
//  calendars, a numeral big enough to read across a room, and underneath it a
//  ruled table cramming in everything the day is and isn't good for.
//
//  The calendar half comes from Lunisolar, the judgements from Almanac. 通勝
//  is the Cantonese name for that almanac, so this page keeps the traditional
//  characters and the Hijri line the Southeast Asian pads print.
//

import SwiftUI

struct TongshengLayout: View {
    let info: DayInfo
    let t: PageTheme




    /// The sheet's one ink. This press runs red, every day of the year.
    private var ink: Color { t.ink }

    /// Table geometry, so the rules line up without guessing.
    private let tableInset: CGFloat = 14
    private let sideColumn: CGFloat = 52

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 28)
            masthead
            hero
            table
            Spacer(minLength: 0)
            footer
            Spacer().frame(height: 11)
        }
    }

    // MARK: - Masthead

    /// Gregorian year and month, with the Hijri date the Malaysian printings
    /// carry in the corner.
    private var masthead: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "\(info.year)")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .italic()
                Text(verbatim: hijri)
                    .font(.system(size: 6, weight: .semibold, design: .serif))
                    .foregroundStyle(ink.opacity(0.8))
            }
            Spacer(minLength: 0)
            Text(verbatim: monthNamesEN[info.month])
                .font(.system(size: 11, weight: .black, design: .serif))
                .tracking(1.2)
                .padding(.top, 2)
            Spacer(minLength: 0)
            Text(verbatim: kanjiNumber(info.month) + "月" + gregorianMonthMark)
                .font(Theme.mincho(14))
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 16)
        .frame(height: 26, alignment: .top)
    }

    /// "1448 22hb" — Hijri year and day, the way the Malay printings set it.
    private var hijri: String {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.timeZone = .current
        let c = cal.dateComponents([.year, .day], from: info.date)
        return "\(c.year ?? 0) \(c.day ?? 0)hb"
    }

    /// A 31-day Gregorian month is 大, anything shorter 小.
    private var gregorianMonthMark: String {
        let days = Calendar(identifier: .gregorian)
            .range(of: .day, in: .month, for: info.date)?.count ?? 30
        return days == 31 ? "大" : "小"
    }

    // MARK: - Hero

    /// The numeral, flanked by the good-fortune couplets and today's moon.
    private var hero: some View {
        ZStack {
            HStack(alignment: .top, spacing: 0) {
                // Tonight's moon rides above the couplet, balancing the seal
                // on the other flank and keeping clear of the numeral.
                VStack(spacing: 5) {
                    Text(verbatim: info.report.dayPillar.label).font(Theme.mincho(9))
                    VerticalText("一帆風順人安康", font: Theme.mincho(7.5), color: ink, spacing: 1.5)
                }
                Spacer(minLength: 0)
                VerticalText("旺丁旺財", font: Theme.mincho(8.5), color: t.paper, spacing: 2)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 3)
                    .background(ink, in: .rect(cornerRadius: 1))
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            VStack(spacing: 0) {
                banner
                Text(verbatim: "\(info.day)")
                    .font(.system(size: 88, weight: .black, design: .serif))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .dayNumberTarget()
            }
        }
        .frame(height: 118)
    }

    /// A festival or solar term gets the ribbon over the numeral; most days
    /// have neither, and the slot stays empty so the numeral never shifts.
    private var banner: some View {
        Group {
            if let name = info.page.holiday?.chinese ?? info.report.termOnDate.map(termName) {
                Text(verbatim: name)
                    .font(Theme.mincho(9))
                    .foregroundStyle(t.paper)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1.5)
                    .background(ink, in: .rect(cornerRadius: 1))
            }
        }
        .frame(height: 15)
    }

    // MARK: - The almanac table

    private var table: some View {
        VStack(spacing: 0) {
            dateRow
            hRule
            if info.calendarLayout {
                MonthGrid(info: info, t: t, customHeaders: Array("日一二三四五六").map(String.init))
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
            } else {
                adviceRow
            }
            hRule
            pillarRow
            hRule
            directionRow
        }
        .overlay(Rectangle().strokeBorder(ink, lineWidth: 1.2))
        .padding(.horizontal, tableInset)
    }

    /// 丙午年 · 十一月大 · 廿四日 · 星期五
    private var dateRow: some View {
        HStack(spacing: 0) {
            Text(verbatim: info.report.yearPillar.label + "年")
                .font(Theme.mincho(10))
                .frame(width: 54)
            vRule
            Text(verbatim: info.report.lunarMonthLabel)
                .font(Theme.mincho(11))
                .frame(width: 62)
            vRule
            Text(verbatim: info.report.lunarDayLabel + "日")
                .font(Theme.mincho(16))
                .frame(maxWidth: .infinity)
            vRule
            VStack(spacing: 0) {
                Text(verbatim: "星期" + ["日", "一", "二", "三", "四", "五", "六"][info.weekday - 1])
                    .font(Theme.mincho(11))
                Text(verbatim: weekdayNamesEN[info.weekday])
                    .font(.system(size: 5.5, weight: .heavy, design: .serif))
                    .tracking(0.4)
            }
            .frame(width: 62)
        }
        .foregroundStyle(ink)
        .frame(height: 32)
    }

    /// 宜 on the left, 忌 on the right, the open hours between them.
    private var adviceRow: some View {
        HStack(spacing: 0) {
            adviceColumn("宜", info.chineseActivities(info.page.recommended, empty: "無所宜"))
                .activityLink(day: info.page.date.label, side: .recommended)
            vRule
            hours
            vRule
            adviceColumn("忌", info.chineseActivities(info.page.avoided, empty: info.report.trace.avoidsEverything ? "諸事皆忌" : "無所忌"))
                .activityLink(day: info.page.date.label, side: .avoided)
        }
        .frame(height: 96)
    }

    private func adviceColumn(_ head: String, _ items: [String]) -> some View {
        VStack(spacing: 3) {
            Text(verbatim: head)
                .font(Theme.mincho(17))
                .foregroundStyle(ink)
            ForEach(items, id: \.self) { item in
                Text(verbatim: item)
                    .font(Theme.mincho(8))
                    .foregroundStyle(ink)
            }
        }
        .frame(width: sideColumn)
    }

    /// The twelve double-hours, the six on the yellow road inked solid.
    private var hours: some View {
        VStack(spacing: 3) {
            Text(verbatim: "吉時")
                .font(Theme.mincho(8))
                .foregroundStyle(ink)
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 1.5) {
                    ForEach(0..<6, id: \.self) { col in
                        hourCell(row * 6 + col)
                    }
                }
            }
            Text(verbatim: info.report.zodiacClash)
                .font(Theme.mincho(9))
                .foregroundStyle(t.paper)
                .padding(.horizontal, 7)
                .padding(.vertical, 1.5)
                .background(ink, in: .rect(cornerRadius: 1))
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
    }

    private func hourCell(_ branch: Int) -> some View {
        let open = !info.report.hourLuckIsInauspicious[branch]
        // 子時 opens at 23:00 and each branch takes the two hours after.
        let start = max(0, branch * 2 - 1)
        return VStack(spacing: -1) {
            Text(verbatim: hourBranches[branch])
                .font(Theme.mincho(8.5))
            Text(verbatim: String(format: "%02d", start))
                .font(.system(size: 5.5, weight: .semibold, design: .serif).monospacedDigit())
        }
        .foregroundStyle(open ? t.paper : ink)
        .frame(width: 24, height: 21)
        .background(open ? AnyShapeStyle(ink) : AnyShapeStyle(.clear))
        .overlay(Rectangle().strokeBorder(ink.opacity(open ? 0 : 0.55), lineWidth: 0.5))
    }

    /// 庚辰 · 金 · 鬼宿 · 定日 — the day pillar and who holds it.
    private var pillarRow: some View {
        HStack(spacing: 0) {
            ForEach([info.report.dayPillar.label, String(info.report.nayin.suffix(1)), info.report.mansion, (info.report.officer + "日")], id: \.self) { part in
                Text(verbatim: part)
                    .font(Theme.mincho(part.count > 2 ? 9 : 11))
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(ink)
        .frame(height: 26)
    }

    /// Where the wealth and joy gods stand, and where the day's killings point.
    private var directionRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(info.report.luckyDirections.prefix(3)), id: \.self) { part in
                Text(verbatim: part)
                    .font(Theme.mincho(8))
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(ink)
        .frame(height: 21)
    }

    // MARK: - Footer

    /// The zodiac year, the moon's own name for the day, and a press seal.
    private var footer: some View {
        HStack(spacing: 6) {
            Text(verbatim: "【\(info.report.yearZodiac)】年")
                .font(Theme.mincho(8))
            Text(verbatim: "百業興旺家富裕")
                .font(Theme.mincho(7))
                .foregroundStyle(ink.opacity(0.75))
            if let phase = info.phase {
                Text(verbatim: phase)
                    .font(Theme.mincho(8))
                    .foregroundStyle(t.paper)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(ink.opacity(0.85), in: .rect(cornerRadius: 1))
            }
            Spacer(minLength: 0)
            Text(verbatim: "通勝")
                .font(Theme.mincho(9))
                .foregroundStyle(t.paper)
                .padding(.horizontal, 3)
                .padding(.vertical, 2)
                .background(ink.opacity(0.9), in: .rect(cornerRadius: 1))
                .rotationEffect(.degrees(-2))
        }
        .foregroundStyle(ink)
        .padding(.horizontal, tableInset)
    }

    // MARK: - Rules

    private var hRule: some View {
        Rectangle().fill(ink.opacity(0.75)).frame(height: 0.7)
    }

    private var vRule: some View {
        Rectangle().fill(ink.opacity(0.75)).frame(width: 0.7)
    }
}
