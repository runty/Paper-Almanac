import XCTest
import AppKit

final class DesktopTests: XCTestCase {
    @MainActor func testAboutBranding() {
        let app = XCUIApplication()
        app.launch()
        let status = app.statusItems["Paper Almanac"]
        status.click()
        status.menuItems["About"].click()
        let about = app.windows["About"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        XCTAssertTrue(about.descendants(matching: .any)["Wadscorp website"].firstMatch.isHittable)
        let proof = XCTAttachment(screenshot: about.screenshot())
        proof.name = "About"
        proof.lifetime = .keepAlways
        add(proof)
    }

    @MainActor func testThemeSwitchKeepsVisibleTopLeft() {
        let app = XCUIApplication()
        app.launchArguments = ["-print.theme", "lichViet", "-desktopCalendarSize", "100"]
        app.launch()
        let pad = app.windows["Paper Almanac"]
        XCTAssertTrue(pad.waitForExistence(timeout: 8))
        let start = pad.frame
        let expectedX = start.midX - 150
        let expectedY = start.minY + 26
        let status = app.statusItems["Paper Almanac"]
        for (title, width, top) in [("Kin’un", 316.0, 2.0), ("Tsukigoyomi", 324.0, 2.0), ("Lịch Việt", 300.0, 26.0)] {
            status.click()
            status.menuItems["Theme"].hover()
            status.menuItems[title].click()
            XCTAssertEqual(pad.frame.midX - width / 2, expectedX, accuracy: 1, title)
            XCTAssertEqual(pad.frame.minY + top, expectedY, accuracy: 1, title)
        }
    }

    @MainActor func testUnbackedCalendarReachesMenuBar() {
        let app = XCUIApplication()
        app.launchArguments = ["-print.theme", "lichViet", "-desktopCalendarSize", "100"]
        app.launch()
        let pad = app.windows["Paper Almanac"]
        XCTAssertTrue(pad.waitForExistence(timeout: 8))
        let start = pad.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
            .withOffset(CGVector(dx: 0, dy: 38))
        let target = start.withOffset(CGVector(dx: 0, dy: -pad.frame.minY - 36))
        start.click(forDuration: 0.2, thenDragTo: target, withVelocity: .slow, thenHoldForDuration: 0.2)
        let screen = NSScreen.main!
        let menuBottom = screen.frame.maxY - screen.visibleFrame.maxY
        XCTAssertEqual(pad.frame.minY + 26, menuBottom, accuracy: 3)
    }

    @MainActor func testBackingBoardDragsMoveWindowAndPaperDragKeepsItInPlace() {
        let app = XCUIApplication()
        for (theme, percent) in [("kinun", 100), ("tsukigoyomi", 150)] {
            app.launchArguments = ["-print.theme", theme, "-desktopCalendarSize", String(percent), "-pad.heldCivilDay", "2027-11-19"]
            app.launch()
            let pad = app.windows["Paper Almanac"]
            XCTAssertTrue(pad.waitForExistence(timeout: 8))
            let scale = CGFloat(percent) / 100
            func drag(x: CGFloat, y: CGFloat, dx: CGFloat) {
                let point = pad.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                    .withOffset(CGVector(dx: x * scale, dy: y * scale))
                point.click(forDuration: 0.12, thenDragTo: point.withOffset(CGVector(dx: dx, dy: 0)), withVelocity: .slow, thenHoldForDuration: 0.15)
            }
            // Grab the header, side rim, bottom rim and binding, then the printed page itself.
            let top: CGFloat = theme == "kinun" ? 46 : 26
            for (x, y, dx) in [(0.0, 12.0, -60.0), (-154, 160, 60), (0, top + 423, -60), (0, top + 12, 60)] {
                let before = pad.frame
                drag(x: x, y: y, dx: dx)
                XCTAssertGreaterThan((pad.frame.minX - before.minX) * (dx > 0 ? 1 : -1), 15, "\(theme) at (\(x), \(y))")
            }
            let before = pad.frame
            drag(x: 0, y: top + 190, dx: -30)
            XCTAssertEqual(pad.frame.minX, before.minX, accuracy: 1)
            app.terminate()
        }
    }

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

    @MainActor func testMenuTearAndReturnToToday() {
        let app = XCUIApplication()
        app.launch()
        let pad = app.windows["Paper Almanac"]
        XCTAssertTrue(pad.waitForExistence(timeout: 8))
        app.typeKey("t", modifierFlags: .command)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        func label(_ days: Int) -> String {
            let c = calendar.dateComponents([.year,.month,.day], from: calendar.date(byAdding: .day, value: days, to: .now)!)
            return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
        }
        func sheet(_ days: Int) -> XCUIElement {
            app.descendants(matching: .any)["daily-sheet-" + label(days)]
        }
        XCTAssertTrue(sheet(0).waitForExistence(timeout: 8))
        let status = app.statusItems["Paper Almanac"]
        status.click()
        let autoChange = status.menuItems["Auto Change Date"]
        XCTAssertTrue(autoChange.isHittable)
        XCTAssertLessThan(status.menuItems["Calendar Size"].frame.midY, autoChange.frame.midY)
        XCTAssertTrue(status.menuItems["Quit"].exists)
        XCTAssertFalse(status.menuItems["Show Daily Almanac"].exists)
        XCTAssertFalse(status.menuItems["Previous Day"].exists)
        XCTAssertFalse(status.menuItems["Next Day"].exists)
        XCTAssertTrue(status.menuItems["Today"].isHittable)
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        let origin = pad.coordinate(withNormalizedOffset: CGVector(dx: 0.604, dy: 0.51))
        origin.click(forDuration: 0.2, thenDragTo: origin.withOffset(CGVector(dx: 12, dy: 220)), withVelocity: .slow, thenHoldForDuration: 0.25)
        XCTAssertTrue(sheet(1).waitForExistence(timeout: 5))
        status.click()
        status.menuItems["Today"].click()
        XCTAssertTrue(sheet(0).waitForExistence(timeout: 5))
    }
}
