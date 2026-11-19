import XCTest
import CoreLocation

final class MobileUITests: XCTestCase {
    private let dates = ["2026-10-31", "2026-11-06", "2026-11-11"]

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run { XCUIDevice.shared.orientation = .portrait }
    }

    @MainActor private func acceptOpen() {
        let open = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Open"]
        if open.exists { open.tap() }
    }
    @MainActor private func show(_ label: String, in app: XCUIApplication) -> XCUIElement {
        app.open(URL(string: "tungshingdaily://day/" + label)!)
        acceptOpen()
        let page = app.descendants(matching: .any)["daily-sheet-" + label]
        XCTAssertTrue(page.waitForExistence(timeout: 12))
        return page
    }
    @MainActor func testPrintedOverflowAndWidgetActivityLink() {
        let app = XCUIApplication()
        let page = show("2026-10-31", in: app)
        page.coordinate(withNormalizedOffset: CGVector(dx: 0.661, dy: 0.76)).tap()
        XCTAssertTrue(app.staticTexts["忌 · Avoid"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Arrange a burial"].exists)
        app.buttons["Done"].tap()
        app.open(URL(string: "tungshingdaily://day/2026-11-06?activities=do")!)
        acceptOpen()
        XCTAssertTrue(app.staticTexts["宜 · Do"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Clean your home"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["daily-sheet-2026-11-06"].exists)
    }

    @MainActor func testMoonUsesSeasonalSkyUntilLocationIsSelected() {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
        let device = XCUIDevice.shared
        let oldLocation = device.location
        device.location = XCUILocation(location: CLLocation(latitude: -33.87, longitude: 151.21))
        defer { device.location = oldLocation }
        app.launch()
        let palette = app.buttons["Theme"]
        let previous = palette.value as? String
        palette.tap()
        app.buttons["Tsukikage"].tap()
        let sheet = show("2027-01-18", in: app)
        let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(sheet.label.contains("Northern sky"))
        XCTAssertFalse(system.alerts.firstMatch.exists)

        func toggleLocation() {
            palette.tap()
            app.descendants(matching: .any)["Use Current Location"].firstMatch.tap()
        }
        toggleLocation()
        let allow = system.buttons["Allow While Using App"]
        XCTAssertTrue(allow.waitForExistence(timeout: 8))
        allow.tap()
        let local = NSPredicate(format: "label CONTAINS %@", "Local sky")
        XCTAssertTrue(app.descendants(matching: .any).matching(local).firstMatch.waitForExistence(timeout: 15))
        XCTAssertTrue(sheet.label.contains("9 PM"))
        toggleLocation()
        XCTAssertTrue(sheet.label.contains("Northern sky"))
        if let previous, previous != "Tsukikage" { palette.tap(); app.buttons[previous].tap() }
    }

    @MainActor func testAboutIncludesFujiCredits() {
        let app = XCUIApplication()
        app.launch()
        let palette = app.buttons["Theme"]
        palette.tap()
        let about = app.buttons["About"]
        let autoChange = app.descendants(matching: .any)["Auto Change Date"].firstMatch
        XCTAssertTrue(autoChange.isHittable)
        XCTAssertLessThan(autoChange.frame.midY, about.frame.midY)
        about.tap()
        XCTAssertTrue(app.staticTexts["Himekuri 日めくり"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["Paper Almanac on GitHub"].firstMatch.isHittable)
        let proof = XCTAttachment(screenshot: app.screenshot())
        proof.name = "About"
        proof.lifetime = .keepAlways
        add(proof)
        let fuji = app.staticTexts["Fuji"]
        let credits = app.scrollViews["about-almanac"]
        for _ in 0..<14 where !fuji.isHittable {
            let start = credits.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
            let end = credits.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.15)
        }
        XCTAssertTrue(fuji.isHittable)
        app.buttons["Done"].tap()
        XCTAssertTrue(palette.waitForExistence(timeout: 5))
    }

    @MainActor func testOriginalLayoutToggle() {
        let app = XCUIApplication()
        app.launch()
        let theme = app.buttons["Theme"]
        let toggle = app.buttons["himekuri-layout"]
        func select(_ title: String) {
            theme.tap()
            app.buttons[title].tap()
        }

        select("Yut Lik")
        select("Shōwa Print")
        let page = show("2026-11-11", in: app)
        XCTAssertTrue(page.label.contains("Month calendar"))
        toggle.tap()
        XCTAssertTrue(page.label.contains("Extend grace"))
        app.terminate()
        app.launch()
        XCTAssertEqual(toggle.label, "Show Month Calendar")

        for title in ["Tong Sheng", "Huangli", "Tong Sheng"] {
            select(title)
            XCTAssertEqual(toggle.label, "Show Month Calendar")
            toggle.tap()
            XCTAssertEqual(toggle.label, "Show Do and Don’t")
        }
        select("Shōwa Print")
        XCTAssertEqual(toggle.label, "Show Do and Don’t")
        select("Twin Pillars")
        XCTAssertFalse(toggle.exists)
        XCTAssertTrue(show("2026-11-11", in: app).label.contains("Extend grace"))
        select("Yut Lik")
    }

    @MainActor func testMaterialBindings() {
        let app = XCUIApplication()
        let page = show("2026-11-06", in: app)
        let palette = app.buttons["Theme"]
        let previous = palette.value as? String
        defer {
            if let previous { palette.tap(); app.buttons[previous].tap() }
        }
        for title in ["Yut Lik", "Editorial Day", "Twin Pillars"] {
            palette.tap()
            app.buttons[title].tap()
            XCTAssertEqual(palette.value as? String, title)
            XCTAssertTrue(page.isHittable)
            let proof = XCTAttachment(screenshot: app.screenshot())
            proof.name = "Binding " + title
            proof.lifetime = .keepAlways
            add(proof)
        }
    }

    @MainActor func testFujiOnCardboard() {
        let app = XCUIApplication()
        app.launch()
        let theme = app.buttons["Theme"]
        let previous = theme.value as? String
        theme.tap()
        app.buttons["Fuji"].tap()
        defer {
            if let previous, previous != "Fuji" { theme.tap(); app.buttons[previous].tap() }
        }
        let page = show("2027-01-01", in: app)
        XCTAssertTrue(page.label.contains("元日"))
        XCTAssertTrue(page.label.contains("仏滅"))
        XCTAssertTrue(page.label.contains("Waning moon"))
        let proof = XCTAttachment(screenshot: app.screenshot())
        proof.name = "Fuji cardboard"
        proof.lifetime = .keepAlways
        add(proof)
    }

    @MainActor func testCelestialEditionOnThePad() {
        let app = XCUIApplication()
        app.launch()
        let theme = app.buttons["Theme"]
        let previous = theme.value as? String
        theme.tap()
        app.buttons["Celestial Almanac"].tap()
        defer {
            if let previous, previous != "Celestial Almanac" {
                theme.tap()
                app.buttons[previous].tap()
            }
        }
        let reference = show("2025-02-22", in: app)
        XCTAssertTrue(reference.label.contains("Senshō"))
        XCTAssertTrue(reference.label.contains("White Tiger"))
        XCTAssertTrue(reference.label.contains("Pisces"))
        let proof = XCTAttachment(screenshot: app.screenshot())
        proof.name = "Celestial mobile pad"
        proof.lifetime = .keepAlways
        add(proof)
        let boundary = show("2023-05-20", in: app)
        XCTAssertTrue(boundary.label.contains("4/1"))
        XCTAssertTrue(boundary.label.contains("Butsumetsu"))
    }

    @MainActor func testRetiredThemeFallsBackToTungShing() {
        for storedTheme in ["brutalist", "calendarPoster", "swiss", "office"] {
            let app = XCUIApplication()
            app.launchArguments = ["-print.theme", storedTheme]
            app.launch()
            let theme = app.buttons["Theme"]
            XCTAssertEqual(theme.value as? String, "Yut Lik")
            theme.tap()
            XCTAssertTrue(app.buttons["Yut Lik"].exists)
            XCTAssertFalse(app.buttons["Minimal Swiss"].exists)
            XCTAssertFalse(app.buttons["Retro Office"].exists)
            XCTAssertFalse(app.buttons["Brutalist"].exists)
            XCTAssertFalse(app.buttons["Stitched Almanac"].exists)
            app.terminate()
        }
    }

    @MainActor func testThemeSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launch()
        let theme = app.buttons["Theme"]
        theme.tap()
        app.buttons["Twin Pillars"].tap()
        XCTAssertEqual(theme.value as? String, "Twin Pillars")
        app.terminate()
        app.launch()
        XCTAssertEqual(theme.value as? String, "Twin Pillars")
        theme.tap()
        app.buttons["Yut Lik"].tap()
        XCTAssertEqual(theme.value as? String, "Yut Lik")
    }

    @MainActor func testLeftAlignedNumeralAndLowerEdgeSwipe() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let theme = app.buttons["Theme"]
        theme.tap()
        app.buttons["Editorial Day"].tap()
        let page = show("2024-02-29", in: app)
        let start = page.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.87))
        start.press(forDuration: 0.05, thenDragTo: page.coordinate(withNormalizedOffset: CGVector(dx: 0.60, dy: 0.87)))
        XCTAssertTrue(page.exists)
        page.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.36)).tap()
        XCTAssertTrue(page.exists)
        page.staticTexts["29"].firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.descendants(matching: .any)[todaySheetID].waitForExistence(timeout: 8))
        theme.tap()
        app.buttons["Yut Lik"].tap()
    }

    @MainActor func testDownwardPullFromDate() {
        let app = XCUIApplication()
        app.launch()
        let page = show("2026-11-06", in: app)
        let start = page.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.36))
        start.press(forDuration: 0.1, thenDragTo: page.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.90)),
                    withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertTrue(app.descendants(matching: .any)["daily-sheet-2026-11-07"].waitForExistence(timeout: 4))
    }

    @MainActor func testShortDownwardPullKeepsThePage() {
        let app = XCUIApplication()
        app.launch()
        let page = show("2026-11-06", in: app)
        let corner = page.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.94))
        corner.press(forDuration: 0.1, thenDragTo: corner.withOffset(CGVector(dx: 2, dy: 70)),
                     withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertTrue(page.exists)
    }

    @MainActor func testQuietLiftThenDiagonalCornerTear() {
        continueAfterFailure = false
        let app = XCUIApplication()
        let page = show("2026-11-06", in: app)
        let corner = page.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.90))
        let binding = page.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.08))
        for _ in 0..<2 {
            corner.press(forDuration: 0.1, thenDragTo: binding, withVelocity: .slow, thenHoldForDuration: 0.35)
            XCTAssertTrue(page.exists, "Lifting straight up to the binding should leave the sheet attached")
        }
        let across = page.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.56))
        corner.press(forDuration: 0.1, thenDragTo: across, withVelocity: .slow, thenHoldForDuration: 0.35)
        XCTAssertTrue(app.descendants(matching: .any)["daily-sheet-2026-11-07"].waitForExistence(timeout: 5))
    }

    private var todaySheetID: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "daily-sheet-" + formatter.string(from: Date())
    }

    @MainActor func testHoldingATornPageAndReturningToToday() {
        continueAfterFailure = false
        let app = XCUIApplication()
        let page = show("2026-11-06", in: app)
        let menu = app.buttons["Theme"]
        menu.tap()
        let automatic = app.descendants(matching: .any)["Auto Change Date"].firstMatch
        XCTAssertTrue(automatic.waitForExistence(timeout: 5))
        automatic.tap()
        defer {
            menu.tap()
            if automatic.waitForExistence(timeout: 5) { automatic.tap() }
        }

        let corner = page.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.90))
        let across = page.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.56))
        corner.press(forDuration: 0.1, thenDragTo: across, withVelocity: .slow, thenHoldForDuration: 0.35)
        let held = app.descendants(matching: .any)["daily-sheet-2026-11-07"]
        XCTAssertTrue(held.waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(held.waitForExistence(timeout: 8))

        menu.tap()
        XCTAssertFalse(app.buttons["Today"].exists)
        app.buttons["go-to-date"].tap()
        let today = app.buttons["Today"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        today.tap()
        XCTAssertTrue(today.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)[todaySheetID].waitForExistence(timeout: 8))
    }

    @MainActor func testAccessibilityReadingReflows() {
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.open(URL(string: "tungshingdaily://day/2026-11-11")!)
        acceptOpen()
        XCTAssertTrue(app.staticTexts["光棍節 · Singles’ Day"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["宜 · Do"].exists)
        XCTAssertTrue(app.staticTexts["忌 · Avoid"].exists)
        let reading = app.scrollViews.firstMatch
        let left = reading.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.35))
        let right = reading.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.35))
        right.press(forDuration: 0.1, thenDragTo: left)
        let date = app.buttons["2026-11-11"]
        XCTAssertTrue(date.exists)
        left.press(forDuration: 0.1, thenDragTo: right)
        XCTAssertTrue(date.exists)
        date.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let today = String(todaySheetID.dropFirst("daily-sheet-".count))
        XCTAssertTrue(app.buttons[today].waitForExistence(timeout: 5))
    }

    @MainActor func testReferencePagesAndMobileNavigation() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        acceptOpen()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        for (i, label) in dates.enumerated() {
            let page = show(label, in: app)
            XCTAssertTrue(page.label.contains(["Nothing recommended", "Clean your home", "Extend grace"][i]))
            let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            image.name = "Reference-" + label
            image.lifetime = .keepAlways
            add(image)
        }
        XCTAssertFalse(app.staticTexts["Daily Almanac"].exists)
        XCTAssertFalse(app.buttons["Previous day"].exists)
        XCTAssertFalse(app.buttons["Next day"].exists)
        XCTAssertFalse(app.buttons["Today"].exists)
        let page = app.descendants(matching: .any)["daily-sheet-2026-11-11"]
        for (x, y, distance) in [(0.46, 0.37, 0.35), (0.72, 0.80, -0.35)] {
            let grip = page.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
            let end = page.coordinate(withNormalizedOffset: CGVector(dx: x + distance, dy: y))
            grip.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
            XCTAssertTrue(page.exists)
        }
        let start = page.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.87))
        start.press(forDuration: 0.1, thenDragTo: page.coordinate(withNormalizedOffset: CGVector(dx: 0.89, dy: 0.55)),
                    withVelocity: .slow, thenHoldForDuration: 0.35)
        XCTAssertTrue(app.descendants(matching: .any)["daily-sheet-2026-11-12"].waitForExistence(timeout: 5))
        let torn = app.descendants(matching: .any)["daily-sheet-2026-11-12"]
        torn.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.75)).tap()
        XCTAssertTrue(app.staticTexts["宜 · Do"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(torn.exists)
        torn.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        XCTAssertTrue(app.descendants(matching: .any)[todaySheetID].waitForExistence(timeout: 8))

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let theme = app.buttons["Theme"]
        let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let frame = app.frame
            return frame.width > frame.height && theme.isHittable && frame.contains(theme.frame)
                && theme.frame.midX > frame.midX
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [rotated], timeout: 10), .completed)
        theme.tap()
        let jump = app.buttons["go-to-date"]
        XCTAssertTrue(jump.waitForExistence(timeout: 5))
        jump.tap()
        XCTAssertTrue(app.buttons["Show"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Show"].waitForNonExistence(timeout: 5))
    }
}
