import XCTest

final class DesktopTests: XCTestCase {
    @MainActor func testCalendarSizeAndScaledPageInteractions() {
        let app = XCUIApplication()
        app.launchArguments = ["-print.theme", "tungShing"]
        app.launch()
        let pad = app.windows["Paper Almanac"]
        func selectSize(_ percent: Int) {
            let status = app.statusItems["Paper Almanac"]
            status.click()
            status.menuItems["Calendar Size"].hover()
            status.menuItems["\(percent)%"].click()
        }
        defer {
            selectSize(100)
            app.typeKey("t", modifierFlags: .command)
        }
        selectSize(100)
        let baseWidth = pad.frame.width
        for (percent, extraWidth) in [(130, 90.0), (150, 150.0)] {
            selectSize(percent)
            XCTAssertEqual(pad.frame.width, baseWidth + extraWidth, accuracy: 1)
        }
        let enlargedFrame = pad.frame
        app.terminate()
        app.launch()
        XCTAssertTrue(pad.waitForExistence(timeout: 8))
        XCTAssertEqual(pad.frame.midX, enlargedFrame.midX, accuracy: 1)
        XCTAssertEqual(pad.frame.minY, enlargedFrame.minY, accuracy: 1)
        XCTAssertEqual(pad.frame.width, baseWidth + 150, accuracy: 1)
        app.open(URL(string: "tungshingdaily://day/2026-10-31")!)
        XCTAssertTrue(app.descendants(matching: .any)["daily-sheet-2026-10-31"].waitForExistence(timeout: 8))
        // Printed Avoid column at 150%, measured from the window's upper center.
        let column = pad.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 75, dy: 525))
        column.click()
        XCTAssertTrue(app.staticTexts["忌 · Avoid"].waitForExistence(timeout: 5))
        app.buttons["Done"].click()
        column.click(forDuration: 0.2, thenDragTo: column.withOffset(CGVector(dx: 12, dy: 210)), withVelocity: .slow, thenHoldForDuration: 0.25)
        XCTAssertTrue(app.descendants(matching: .any)["daily-sheet-2026-11-01"].waitForExistence(timeout: 5))
    }

    @MainActor func testWidgetDateLinkOnColdLaunch() {
        let app = XCUIApplication()
        app.terminate()
        app.open(URL(string: "tungshingdaily://day/2026-11-11")!)
        XCTAssertTrue(app.descendants(matching: .any)["daily-sheet-2026-11-11"].waitForExistence(timeout: 10))
        app.typeKey("t", modifierFlags: .command)
    }
    @MainActor func testClickPrintedAvoidOverflow() {
        let app = XCUIApplication()
        app.launchArguments = ["-print.theme", "tungShing"]
        app.launch()
        app.open(URL(string: "tungshingdaily://day/2026-10-31")!)
        let page = app.descendants(matching: .any)["daily-sheet-2026-10-31"]
        XCTAssertTrue(page.waitForExistence(timeout: 10))
        // Click the activities, well above the overflow count.
        app.windows["Paper Almanac"].coordinate(withNormalizedOffset: CGVector(dx: 0.604, dy: 0.51)).click()
        XCTAssertTrue(app.staticTexts["忌 · Avoid"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Arrange a burial"].exists)
        XCTAssertFalse(app.windows["Paper Almanac"].sheets.firstMatch.exists)
        app.buttons["Done"].click()
        XCTAssertTrue(page.exists)
        app.typeKey("t", modifierFlags: .command)
    }

    @MainActor func testLiftingLowerLeftCornerKeepsDateUntilPulledAcross() {
        let app = XCUIApplication()
        app.launch()
        defer { app.typeKey("t", modifierFlags: .command) }
        app.open(URL(string: "tungshingdaily://day/2026-10-31")!)
        let current = app.descendants(matching: .any)["daily-sheet-2026-10-31"]
        XCTAssertTrue(current.waitForExistence(timeout: 8))
        let pad = app.windows["Paper Almanac"]
        let scale = (pad.frame.width - 180) / 300
        let grip = pad.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: -135 * scale, dy: 405 * scale))
        for travel in [60, 90, -345] {
            grip.click(forDuration: 0.1, thenDragTo: grip.withOffset(CGVector(dx: 0, dy: CGFloat(travel) * scale)))
            XCTAssertTrue(current.exists)
        }
        grip.click(forDuration: 0.1, thenDragTo: grip.withOffset(CGVector(dx: 195 * scale, dy: -130 * scale)), withVelocity: .slow, thenHoldForDuration: 0.25)
        XCTAssertTrue(app.descendants(matching: .any)["daily-sheet-2026-11-01"].waitForExistence(timeout: 5))
    }

    @MainActor func testBrowseTearAndReturnToToday() throws {
        let app = XCUIApplication()
        app.launch()
        let pad = app.windows["Paper Almanac"]
        XCTAssertTrue(pad.waitForExistence(timeout: 8))
        app.typeKey("t", modifierFlags: .command)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        func sheet(_ days: Int) -> XCUIElement {
            let c = calendar.dateComponents([.year,.month,.day], from: calendar.date(byAdding: .day, value: days, to: .now)!)
            let label = String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
            return app.descendants(matching: .any)["daily-sheet-" + label]
        }
        XCTAssertTrue(sheet(0).waitForExistence(timeout: 8))
        app.typeKey("]", modifierFlags: .command)
        XCTAssertTrue(sheet(1).waitForExistence(timeout: 5))
        let status = app.statusItems["Paper Almanac"]
        status.click()
        status.menuItems["Today"].click()
        XCTAssertTrue(sheet(0).waitForExistence(timeout: 5))
        let origin = pad.coordinate(withNormalizedOffset: CGVector(dx: 0.604, dy: 0.51))
        origin.click(forDuration: 0.2, thenDragTo: origin.withOffset(CGVector(dx: 12, dy: 220)), withVelocity: .slow, thenHoldForDuration: 0.25)
        XCTAssertTrue(sheet(1).waitForExistence(timeout: 5))
        app.typeKey("t", modifierFlags: .command)
    }
}
