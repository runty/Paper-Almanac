import SwiftUI
import WidgetKit
import XCTest

final class MobileWidgetTests: XCTestCase {
    private var portraitWidgetSize: CGSize {
        UIDevice.current.userInterfaceIdiom == .pad
            ? CGSize(width: 342, height: 529)
            : CGSize(width: 350, height: 566)
    }
    func testWindowsKeepTheirBrowsedPageWhenAnotherWindowTears() {
        var date = PadDates(today: "2026-11-06", advance: nil)
        date.browse("2026-10-31")
        date.refresh("2026-11-06", persistedAdvance: "2026-11-07")
        XCTAssertEqual(date.visible, "2026-10-31")
        XCTAssertEqual(date.live, "2026-11-07")
        date.refresh("2026-11-09", persistedAdvance: "2026-11-07")
        XCTAssertEqual(date.live, "2026-11-09")
        XCTAssertEqual(date.visible, "2026-10-31")
    }

    @MainActor func testFullWidthTungShingPages() async throws {
        let days = try await DayReader.load(["2026-10-31", "2026-11-11", "2026-11-17"])
        for day in days {
            let sheet = Sheet(label: day.date.label, page: day)
            let entry = DailyEntry(date: .now, sheet: sheet, theme: .tungShing)
            let face = WidgetFace(entry: entry, family: .systemLarge)
                .frame(width: 378, height: 394)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            let renderer = ImageRenderer(content: face)
            renderer.scale = 3
            let image = try XCTUnwrap(renderer.uiImage)
            XCTAssertEqual(image.cgImage?.width, 1134)
            XCTAssertEqual(image.cgImage?.height, 1182)
            let proof = XCTAttachment(image: image)
            proof.name = "Borderless-large-" + sheet.label
            proof.lifetime = .keepAlways
            add(proof)
        }
    }

    @MainActor func testOtherWidgetFacesAcrossFamilies() async throws {
        let days = try await DayReader.load(["2026-11-17", "2026-08-31"])
        let families: [(WidgetFamily, CGSize)] = [
            (.systemSmall, CGSize(width: 158, height: 158)),
            (.systemMedium, CGSize(width: 338, height: 158)),
            (.systemLarge, CGSize(width: 378, height: 394)),
            (.systemExtraLarge, CGSize(width: 715, height: 338)),
            (.systemExtraLargePortrait, portraitWidgetSize)
        ]
        for theme in DailyTheme.allCases where theme != .tungShing {
            for calendar in theme.original == nil ? [false] : [false, true] {
                let page = days[calendar ? 1 : 0] // August 2026 includes a sixth calendar row.
                let sheet = Sheet(label: page.date.label, page: page)
                let entry = DailyEntry(date: .now, sheet: sheet, theme: theme, calendarLayout: calendar)
                for (family, size) in families where family != .systemExtraLarge || UIDevice.current.userInterfaceIdiom == .pad {
                    let face = WidgetFace(entry: entry, family: family)
                        .frame(width: size.width, height: size.height)
                        .background(theme.widgetPaper)
                        .clipShape(RoundedRectangle(cornerRadius: family == .systemLarge ? 32 : 22, style: .continuous))
                    let renderer = ImageRenderer(content: face)
                    renderer.scale = 2
                    let image = try XCTUnwrap(renderer.uiImage)
                    XCTAssertEqual(image.size, size)
                    let proof = XCTAttachment(image: image)
                    proof.name = [theme.title, calendar ? "Calendar" : "Activities", String(describing: family)].joined(separator: "-")
                    proof.lifetime = .keepAlways
                    add(proof)
                }
            }
        }
    }

    @MainActor func testDashboardReadingsInDayAndNightAppearance() async throws {
        let days = try await DayReader.load(["2026-10-31", "2026-11-06", "2026-11-11"])
        var holidayActivityFaces = Set<Data>()
        for theme in DailyTheme.allCases {
            for calendar in theme.original == nil ? [false] : [false, true] {
                for page in days {
                    let entry = DailyEntry(date: DayInfo(page: page).date, sheet: Sheet(label: page.date.label, page: page),
                                           theme: theme, calendarLayout: calendar)
                    var appearances: [Data] = []
                    for scheme in [ColorScheme.light, .dark] {
                        let view = DashboardAlmanac(entry: entry)
                            .padding(14).frame(width: 158, height: 158)
                            .background(scheme == .dark ? Color(white: 0.09) : Color(white: 0.96))
                            .environment(\.colorScheme, scheme)
                        let renderer = ImageRenderer(content: view)
                        renderer.scale = 2
                        let image = try XCTUnwrap(renderer.uiImage)
                        XCTAssertEqual(image.size, CGSize(width: 158, height: 158))
                        appearances.append(try XCTUnwrap(image.pngData()))
                        let proof = XCTAttachment(image: image)
                        proof.name = [page.date.label, theme.title, calendar ? "Calendar" : "Activities",
                                      scheme == .dark ? "Night" : "Day"].joined(separator: "@")
                        proof.lifetime = .keepAlways
                        add(proof)
                    }
                    XCTAssertNotEqual(appearances[0], appearances[1])
                    if !calendar && page.date.label == "2026-11-11" {
                        XCTAssertTrue(holidayActivityFaces.insert(appearances[0]).inserted, theme.title)
                    }
                }
            }
        }
    }

    func testWidgetInstancesKeepIndependentThemes() async throws {
        let query = WidgetThemeQuery()
        let choices = try await query.suggestedEntities()
        let restored = try await query.entities(for: choices.map(\.id))
        XCTAssertEqual(restored.map(\.id), choices.map(\.id))
        XCTAssertEqual(choices.compactMap(\.fixedTheme), DailyTheme.allCases)
        let defaultChoice = await query.defaultResult()
        let following = AlmanacWidgetConfiguration()
        XCTAssertEqual(defaultChoice?.id, following.theme?.id)
        XCTAssertNil(following.theme?.fixedTheme)

        let unconfigured = AlmanacWidgetConfiguration()
        unconfigured.theme = nil
        XCTAssertEqual(unconfigured.selectedTheme.id, following.selectedTheme.id)

        let pins: [DailyTheme] = [.twinPillars, .moon, .koyomi]
        let widgets = pins.map { theme in
            let configuration = AlmanacWidgetConfiguration()
            configuration.theme = WidgetThemeChoice(fixedTheme: theme)
            return configuration
        } + [following]

        let defaults = DailyTheme.defaults
        let previousTheme = defaults.object(forKey: DailyTheme.key)
        defer { defaults.set(previousTheme, forKey: DailyTheme.key) }
        for appTheme in [DailyTheme.fuji, .kinun] {
            defaults.set(appTheme.rawValue, forKey: DailyTheme.key)
            for (widget, expected) in zip(widgets, pins + [appTheme]) {
                let entries = await DailyProvider().entries(starting: .now, zone: .gmt, choice: widget.selectedTheme)
                XCTAssertEqual(entries.map(\.theme), Array(repeating: expected, count: 5))
            }
        }
    }

    @MainActor func testWidgetTimelineAndSupportedSizes() async throws {
        let day = ISO8601DateFormatter().date(from: "2026-11-11T12:00:00Z")!
        let entries = await DailyProvider().entries(starting: day, zone: .gmt, choice: WidgetThemeChoice(fixedTheme: .tungShing))
        let first = try XCTUnwrap(entries.first)
        XCTAssertEqual(entries.map(\.sheet.label), (11...15).map { "2026-11-\($0)" })
        XCTAssertEqual(first.sheet.page?.holiday?.english, "Singles’ Day")
        let families: [(WidgetFamily, CGSize)] = [
            (.systemSmall, CGSize(width: 158, height: 158)),
            (.systemMedium, CGSize(width: 338, height: 158)),
            (.systemLarge, CGSize(width: 338, height: 354)),
            (.systemExtraLarge, CGSize(width: 715, height: 338)),
            (.systemExtraLargePortrait, portraitWidgetSize)
        ]
        for (family, size) in families where family != .systemExtraLarge || UIDevice.current.userInterfaceIdiom == .pad {
            let view = WidgetFace(entry: first, family: family)
                .frame(width: size.width, height: size.height)
                .background(first.theme.widgetPaper)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            XCTAssertEqual(image.size.width, size.width, accuracy: 1)
            var original = DailyEntry(date: first.date, sheet: first.sheet, theme: .showa, calendarLayout: false)
            func pixels(calendar: Bool) throws -> Data {
                original.calendarLayout = calendar
                let content = WidgetFace(entry: original, family: family).frame(width: size.width, height: size.height)
                return try XCTUnwrap(ImageRenderer(content: content).uiImage?.pngData())
            }
            XCTAssertNotEqual(try pixels(calendar: false), try pixels(calendar: true))
            let proof = XCTAttachment(image: image)
            proof.name = "HomeWidget-\(family)"
            proof.lifetime = .keepAlways
            add(proof)
        }
    }
}
