import AppKit
import SwiftUI
import WidgetKit
import XCTest

final class PhaseOneTests: XCTestCase {
    func testPaperStackTracksDisplayedDayAcrossYearBoundaries() {
        XCTAssertEqual(CivilDay.remainingPaper(on: "2026-01-01"), 1)
        XCTAssertEqual(CivilDay.remainingPaper(on: "2026-07-02"), 0.5)
        XCTAssertEqual(CivilDay.remainingPaper(on: "2026-12-30"), 1.0 / 364)
        XCTAssertEqual(CivilDay.remainingPaper(on: "2026-12-31"), 0)
        XCTAssertEqual(CivilDay.remainingPaper(on: "2027-01-01"), 1)
        XCTAssertEqual(CivilDay.remainingPaper(on: "2028-02-29"), 306.0 / 365)
    }

    func testUntornAndDeliberatelyAdvancedPadsAcrossMidnightAndWake() {
        var pad = PadDates(today: "2026-11-06", advance: nil)
        pad.refresh("2026-11-07")
        XCTAssertEqual(pad.visible, "2026-11-07")
        pad.refresh("2026-11-11")
        XCTAssertEqual(pad.visible, "2026-11-11")
        pad.tear(); pad.tear()
        XCTAssertEqual(pad.advance, "2026-11-13")
        var reopened = PadDates(today: "2026-11-12", advance: pad.advance)
        XCTAssertEqual(reopened.visible, "2026-11-13")
        reopened.refresh("2026-11-13")
        XCTAssertNil(reopened.advance)
        reopened.refresh("2026-11-12") // westbound across midnight
        XCTAssertEqual(reopened.visible, "2026-11-12")
        reopened.browse("2026-10-31"); reopened.refresh("2026-11-14"); reopened.tear()
        XCTAssertEqual(reopened.visible, "2026-11-01")
        XCTAssertEqual(reopened.live, "2026-11-14")
        reopened.returnToToday()
        XCTAssertEqual(reopened.visible, "2026-11-14")
    }
    func testHeldPadKeepsTornDateAcrossMidnightAndRelaunch() {
        var pad = PadDates(today: "2026-11-06", advance: "2026-11-07")
        pad.setAutomaticallyUpdatesDate(false)
        pad.refresh("2026-11-10")
        XCTAssertEqual(pad.visible, "2026-11-07")
        pad.tear()
        XCTAssertEqual(pad.heldDay, "2026-11-08")

        var reopened = PadDates(today: "2026-11-11", advance: nil, heldDay: pad.heldDay)
        XCTAssertFalse(reopened.automaticallyUpdatesDate)
        XCTAssertEqual(reopened.visible, "2026-11-08")

        reopened.browse("2026-10-31")
        XCTAssertEqual(reopened.heldDay, "2026-11-08")
        reopened.tear()
        XCTAssertEqual(reopened.heldDay, "2026-11-01")
        reopened.returnToToday()
        XCTAssertEqual(reopened.visible, "2026-11-11")
        reopened.refresh("2026-11-12")
        XCTAssertEqual(reopened.visible, "2026-11-11")

        reopened.setAutomaticallyUpdatesDate(true)
        XCTAssertTrue(reopened.automaticallyUpdatesDate)
        XCTAssertEqual(reopened.visible, "2026-11-12")
        reopened.refresh("2026-11-13")
        XCTAssertEqual(reopened.visible, "2026-11-13")
    }

    func testEnablingAutomaticUpdatesKeepsAFuturePageUntilTodayCatchesUp() {
        var pad = PadDates(today: "2026-11-06", advance: nil)
        pad.browse("2026-11-10")
        pad.setAutomaticallyUpdatesDate(false)
        XCTAssertEqual(pad.heldDay, "2026-11-10")
        pad.setAutomaticallyUpdatesDate(true)
        XCTAssertEqual(pad.advance, "2026-11-10")
        pad.refresh("2026-11-10")
        XCTAssertNil(pad.advance)
        pad.refresh("2026-11-11")
        XCTAssertEqual(pad.visible, "2026-11-11")
    }

    func testRangeAndInvalidNavigation() {
        XCTAssertNil(CivilDay.step("1901-01-01", -1))
        XCTAssertNil(CivilDay.step("2100-12-31", 1))
        var pad = PadDates(today: "2026-11-11", advance: "9999-12-31")
        pad.browse("2026-02-30"); XCTAssertEqual(pad.visible, "2026-11-11")
        pad.browse("2100-12-31"); pad.tear(); XCTAssertEqual(pad.visible, "2100-12-31")
    }
    func testRealWidgetTimelineAcrossDSTAndEngineEndpoints() async throws {
        // New York changes its clocks on March 8, 2026.
        let zone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let start = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-03-08T04:30:00Z"))
        let entries = await DailyProvider().entries(starting: start, zone: zone, theme: .editorialDay)
        XCTAssertEqual(entries.map(\.sheet.label), ["2026-03-07","2026-03-08","2026-03-09","2026-03-10","2026-03-11"])
        XCTAssertEqual(entries[2].date.timeIntervalSince(entries[1].date), 23 * 3600)
        for e in entries {
            XCTAssertEqual(e.sheet.page?.date.label, e.sheet.label)
            XCTAssertEqual(e.theme, .editorialDay)
        }
        let edge = try await DayReader.load(["1901-01-01","2100-12-31"])
        XCTAssertEqual(edge.first?.date.label, "1901-01-01")
        XCTAssertEqual(edge.last?.date.label, "2100-12-31")
    }
    @MainActor func testSmallWidgetsHaveNoInsetPerimeter() async throws {
        let pages = try await DayReader.load(["2026-11-17"])
        let page = try XCTUnwrap(pages.first)
        for theme in DailyTheme.allCases {
            for calendar in theme.original == nil ? [false] : [false, true] {
                let entry = DailyEntry(date: DayInfo(page: page).date, sheet: Sheet(label: page.date.label, page: page),
                                       theme: theme, calendarLayout: calendar)
                let face = WidgetFace(entry: entry, family: .systemSmall)
                    .frame(width: 158, height: 158).background(theme.widgetPaper)
                let renderer = ImageRenderer(content: face)
                renderer.scale = 2
                let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
                let paper = try XCTUnwrap(image.colorAt(x: 0, y: 0))
                // The former one-point ink rectangle was inset four points.
                for inset in 6...11 {
                    for y in [inset, image.pixelsHigh - 1 - inset] {
                        let ink = (18..<(image.pixelsWide - 18)).filter { image.colorAt(x: $0, y: y) != paper }
                        XCTAssertLessThan(ink.count, image.pixelsWide / 2, theme.title)
                    }
                }
                if theme == .tungShing {
                    let png = try XCTUnwrap(image.representation(using: .png, properties: [:]))
                    let proof = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                    proof.name = "Small-November-17"
                    proof.lifetime = .keepAlways
                    add(proof)
                }
            }
        }
    }

    @MainActor func testCelestialReferencePages() async throws {
        let pages = try await DayReader.load(["2024-01-06", "2025-02-22", "2026-02-15"])
        let readings = [("Vermilion Bird", "24.5"), ("White Tiger", "23.9"), ("Black Tortoise", "27.6")]
        for (page, expected) in zip(pages, readings) {
            let value = CelestialReading(page)
            XCTAssertEqual(value.tradition.guardian, expected.0)
            XCTAssertEqual(value.moonAge, expected.1)
            XCTAssertFalse(value.history.text.isEmpty)
            let sheet = Sheet(label: page.date.label, page: page)
            let renderer = ImageRenderer(content: SheetView(sheet: sheet, theme: .celestialAlmanac))
            renderer.scale = 3
            let cg = try XCTUnwrap(renderer.cgImage)
            let image = NSBitmapImageRep(cgImage: cg)
            let proof = XCTAttachment(data: try XCTUnwrap(image.representation(using: .png, properties: [:])),
                                      uniformTypeIdentifier: "public.png")
            proof.name = "Celestial-" + page.date.label
            proof.lifetime = .keepAlways
            add(proof)
        }
    }

    @MainActor func testPrintedProverbRotation() async throws {
        let days = try await DayReader.load(["2026-03-30", "2026-04-05", "2026-04-06", "1901-01-01"])
        let readings = try days.map { try XCTUnwrap(ChineseProverb.on($0.date)) }
        XCTAssertEqual(readings[0], readings[1])
        XCTAssertNotEqual(readings[1], readings[2])
        XCTAssertGreaterThan(ChineseProverb.entries.count, 200)
        XCTAssertEqual(Set(ChineseProverb.entries.map(\.headword)).count, ChineseProverb.entries.count)
        let sheet = Sheet(label: days[1].date.label, page: days[1])
        XCTAssertTrue(sheet.description(for: .tungShing, calendarLayout: false).contains(readings[1].english))
        let renderer = ImageRenderer(content: SheetView(sheet: sheet, theme: .tungShing))
        renderer.scale = 3
        let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
        let proof = XCTAttachment(data: try XCTUnwrap(image.representation(using: .png, properties: [:])),
                                  uniformTypeIdentifier: "public.png")
        proof.name = "Proverb-2026-04-05"
        proof.lifetime = .keepAlways
        add(proof)
    }

    func testJapaneseProverbEdition() {
        XCTAssertGreaterThanOrEqual(Proverbs.all.count, 140)
        let count = Int64(Proverbs.all.count)
        let rotation = (-5..<(count - 5)).map { Proverbs.on(dayID: $0).jp }
        XCTAssertEqual(Set(rotation).count, Proverbs.all.count)
        XCTAssertEqual(rotation.first, Proverbs.on(dayID: count - 5).jp)
    }

    @MainActor func testNihonPrintedReferenceDates() async throws {
        let pages = try await DayReader.load(["2027-02-19", "2027-02-20", "2027-03-21"])
        let readings = pages.map(NihonReading.init)
        XCTAssertEqual(readings.map(\.oldDate), ["旧1月13日", "旧1月14日", "旧2月14日"])
        XCTAssertEqual(readings.map(\.mansion), ["婁", "胃", "昴"])
        XCTAssertEqual(readings.map(\.rokuyo), ["先勝", "友引", "先負"])
        XCTAssertEqual(readings.map(\.tide), ["中潮", "大潮", "大潮"])
        XCTAssertEqual(readings[2].holiday, "春分の日")
        XCTAssertEqual(readings.map(\.age), ["12.5", "13.5", "12.7"])
        XCTAssertNotEqual(readings[0].info.proverb.jp, readings[1].info.proverb.jp)
        for page in pages {
            let renderer = ImageRenderer(content: SheetView(sheet: Sheet(label: page.date.label, page: page), theme: .nihon))
            renderer.scale = 3
            let image = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
            let proof = XCTAttachment(data: try XCTUnwrap(image.representation(using: .png, properties: [:])),
                                      uniformTypeIdentifier: "public.png")
            proof.name = "Nihon-" + page.date.label
            proof.lifetime = .keepAlways
            add(proof)
        }
    }

    @MainActor func testMoonOrdinaryDarkSkyAndAnniversaryPages() async throws {
        let pages = try await DayReader.load(["2027-01-18", "2027-01-07", "2027-07-20", "1950-07-20"])
        XCTAssertFalse(MoonReading(pages[0]).darkSky)
        XCTAssertTrue(MoonReading(pages[1]).darkSky)
        XCTAssertEqual(MoonReading(pages[1]).constellation, .orion)
        XCTAssertEqual(MoonReading(pages[2]).milestone?.name, "Apollo 11")
        XCTAssertNil(MoonReading(pages[3]).milestone)
        let sydney = MoonReading(pages[1], site: SkySite(latitude: -34, longitude: 151),
                                 zone: try XCTUnwrap(TimeZone(identifier: "Australia/Sydney")))
        XCTAssertNotNil(sydney.localSky)
        XCTAssertTrue(sydney.note.contains("9 PM"))
        XCTAssertTrue(sydney.caption.contains("Local sky"))
        XCTAssertTrue(MoonReading(pages[1]).caption.contains("Northern sky"))
        let midsummer = try await DayReader.load(["2027-06-21"])[0]
        let midnightSun = MoonReading(midsummer, site: SkySite(latitude: 78, longitude: 16),
                                     zone: try XCTUnwrap(TimeZone(identifier: "Europe/Oslo")))
        XCTAssertEqual(midnightSun.localSky?.darkEnough, false)
        XCTAssertTrue(midnightSun.note.contains("still bright"))
        for page in pages.prefix(3) {
            let sheet = Sheet(label: page.date.label, page: page)
            let renderer = ImageRenderer(content: SheetView(sheet: sheet, theme: .moon))
            renderer.scale = 3
            let cg = try XCTUnwrap(renderer.cgImage)
            let png = try XCTUnwrap(NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]))
            let proof = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
            proof.name = "Moon-" + page.date.label
            proof.lifetime = .keepAlways
            add(proof)
        }
    }

    @MainActor func testFujiReferenceAndWeekday() async throws {
        let pages = try await DayReader.load(["2027-01-01", "2027-01-04"])
        for (index, page) in pages.enumerated() {
            let reading = FujiReading(page)
            if index == 0 {
                XCTAssertEqual(reading.weekday, "FRIDAY")
                XCTAssertEqual(reading.holiday, "元日")
                XCTAssertEqual(reading.rokuyo, "仏滅")
                XCTAssertTrue(reading.redDate)
                XCTAssertEqual(reading.sky?.moonIsWaxing, false)
            } else {
                XCTAssertNil(reading.holiday)
                XCTAssertFalse(reading.redDate)
                XCTAssertNil(reading.holidayLine)
            }
            let renderer = ImageRenderer(content: SheetView(sheet: Sheet(label: page.date.label, page: page), theme: .fuji))
            renderer.scale = 3
            let proof = XCTAttachment(image: try XCTUnwrap(renderer.nsImage))
            proof.name = "Fuji-" + page.date.label
            proof.lifetime = .keepAlways
            add(proof)
        }
    }

    @MainActor func testDistinctLargePagesAndWidgetFaces() async throws {
        let pages = try await DayReader.load(["2026-10-31","2026-11-06","2026-11-11"])
        let page = pages[2]
        let sheet = Sheet(label: page.date.label, page: page)
        var rendered = Set<Data>()
        XCTAssertEqual(DailyTheme(rawValue: "tungShing")?.title, "Yut Lik")
        XCTAssertEqual(DailyTheme(rawValue: "deskBlock")?.title, "Desk Ledger")
        XCTAssertNil(DailyTheme(rawValue: "brutalist"))
        XCTAssertNil(DailyTheme(rawValue: "calendarPoster"))
        XCTAssertEqual(DailyTheme.allCases, [.tungShing, .celestialAlmanac, .editorialDay, .tongsheng, .huangli, .fuji, .moon, .nihon,
                                             .showa, .koyomi, .deskLedger, .almanacColumns])
        XCTAssertEqual(DailyTheme.allCases.filter(\.opensWithCalendar), [.showa, .koyomi])
        for example in pages {
            let exampleSheet = Sheet(label: example.date.label, page: example)
            for theme in DailyTheme.allCases {
                for calendar in theme.original == nil ? [false] : [false, true] {
                    let face = SheetView(sheet: exampleSheet, theme: theme, calendarLayout: calendar)
                    let cg = try XCTUnwrap(ImageRenderer(content: face).cgImage)
                    let image = NSBitmapImageRep(cgImage: cg)
                    let png = try XCTUnwrap(image.representation(using: .png, properties: [:]))
                    XCTAssertTrue(rendered.insert(png).inserted, theme.title)
                    XCTAssertEqual(cg.width, 300)
                    XCTAssertEqual(cg.height, 400)
                    if example.date.label == "2026-11-11" {
                        let proof = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                        proof.name = theme.rawValue + (calendar ? "-calendar" : "-activities")
                        proof.lifetime = .keepAlways
                        add(proof)
                    }
                }
            }
        }
        XCTAssertEqual(rendered.count, 48)
        let leapDay = try await DayReader.load(["2024-02-29"])[0]
        let february = DayInfo(page: leapDay).grid
        XCTAssertEqual(february.first, [nil, nil, nil, nil, 1, 2, 3])
        XCTAssertEqual(february.last, [25, 26, 27, 28, 29, nil, nil])
        XCTAssertEqual(DayInfo(page: pages[0]).grid.count, 5)
        let sixWeeks = try await DayReader.load(["2026-08-31"])[0]
        XCTAssertEqual(DayInfo(page: sixWeeks).grid.count, 6)
        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
            let width: CGFloat = family == .systemSmall ? 155 : 329
            let height: CGFloat = family == .systemLarge ? 345 : 155
            let face = WidgetFace(entry: DailyEntry(date: Date.now, sheet: sheet, theme: .tungShing), family: family)
                .frame(width: width, height: height)
            let renderer = ImageRenderer(content: face)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.nsImage)
            let attachment = XCTAttachment(image: image)
            attachment.name = "Holiday widget \(family)"; attachment.lifetime = .keepAlways; add(attachment)
        }
        let weekendFestival = try await DayReader.load(["2027-02-06"])[0]
        XCTAssertEqual(weekendFestival.date.weekdaySunday0, 6)
        XCTAssertEqual(weekendFestival.holiday?.english, "Lunar New Year")
        XCTAssertEqual(pages[0].recommended.lines, ["Nothing recommended"])
        XCTAssertEqual(pages[1].recommended.lines.count, 4)
        XCTAssertNotNil(page.holiday)
    }
}

final class ActivityPreferenceTests: XCTestCase {
    func testDatedEvidenceHasPriorityWithoutAddingOrCrossingSides() {
        let candidates = ["栽种","出行","剃头","扫舍宇","宴会","立券"]
        let ranked = ActivityPreference.rank(candidates, date: "2026-04-01", side: .recommended)
        XCTAssertEqual(ranked.first, "宴会")
        XCTAssertEqual(Set(ranked), Set(candidates))
        let avoid = ActivityPreference.rank(["嫁娶","栽种"], date: "2026-04-01", side: .avoided)
        XCTAssertEqual(avoid.first, "栽种")
        XCTAssertEqual(ActivityPreference.labels["扫舍宇"], "Clean your home")
        XCTAssertEqual(ActivityPreference.labels["栽种"], "Grow plants")
        XCTAssertEqual(ActivityPreference.labels["进人口"], "Welcome new household members")
        XCTAssertEqual(Set(ActivityPreference.labels.keys), Set(ActivityGlosses.table.keys))
        XCTAssertEqual(ActivityPreference.labels["覃恩"], "Extend grace")
        XCTAssertEqual(ActivityPreference.labels["整手足甲"], "Trim Nails")
    }
    func testRankingDoesNotInventPicturedActivitiesAndGeneralizesBeyondSample() {
        XCTAssertEqual(ActivityPreference.rank(["入学"], date: "2026-11-17", side: .recommended), ["入学"])
        let outside = ActivityPreference.rank(["上册","扫舍宇"], date: "2027-01-01", side: .recommended)
        XCTAssertEqual(outside, ["扫舍宇","上册"])
        XCTAssertEqual(ActivityPreference.rank(["上册","上表章"], date: "2027-01-01", side: .recommended), ["上册","上表章"])
    }
}

final class ReviewedWordingTests: XCTestCase {
    func testHiddenActivitiesCannotUseDisplaySlots() {
        XCTAssertEqual(ActivityPreference.hidden.count, 18)
        XCTAssertTrue(ActivityPreference.hidden.contains("补垣"))
        XCTAssertTrue(ActivityPreference.hidden.contains("启攒"))
        for side in [ActivityPreference.Side.recommended, .avoided] {
            let visible = ["扫舍宇", "栽种", "出行", "剃头"]
            let candidates = Array(ActivityPreference.hidden) + visible
            let ranked = ActivityPreference.rank(candidates, date: "2026-11-11", side: side)
            XCTAssertEqual(Set(ranked), Set(visible))
            XCTAssertEqual(ranked.count, 4)
            XCTAssertEqual(ActivityPreference.rank(Array(ActivityPreference.hidden), date: "2026-11-11", side: side), [])
        }
        XCTAssertEqual(ActivityPreference.labels["补垣"], "Home renovations")
        XCTAssertEqual(ActivityPreference.labels["赴任"], "Start a new job")
        XCTAssertEqual(ActivityPreference.labels["上册"], "Submit records")
        XCTAssertEqual(ActivityPreference.labels["修置产室"], "Prepare a birth room")
    }

    func testSharedReadingsUseReviewedLabelsAndVisibleCounts() async throws {
        let pages = try await DayReader.load(["2026-10-31", "2026-11-06", "2026-11-11"])
        for page in pages {
            for (list, reading) in [(page.report.recommendations, page.recommended), (page.report.avoidances, page.avoided)] {
                let count = list.filter { !$0.isSentinel && !ActivityPreference.hidden.contains($0.rawValue) }.count
                XCTAssertTrue(Set(reading.tokens).isDisjoint(with: ActivityPreference.hidden))
                XCTAssertEqual(reading.remaining, max(0, count - 4))
                XCTAssertEqual(reading.allLines.count, reading.lines.count + reading.remaining)
                let expected = list.filter { !$0.isSentinel && !ActivityPreference.hidden.contains($0.rawValue) }
                    .map { ActivityPreference.labels[$0.rawValue] ?? $0.rawValue }
                if !expected.isEmpty { XCTAssertEqual(reading.allLines.sorted(), expected.sorted()) }
                if !reading.tokens.isEmpty { XCTAssertEqual(reading.lines, reading.tokens.map { ActivityPreference.labels[$0]! }) }
            }
        }
        XCTAssertEqual(pages[0].recommended.lines, ["Nothing recommended"])
        XCTAssertEqual(pages[2].recommended.lines, ["Aid the orphaned and alone", "Extend grace", "Clear a wrong"])
    }
}
