import XCTest

/// Launching, signing in with Quick Connect (scripts/xctest.sh approves the code as the admin),
/// waiting, and saving screenshots to /tmp/jfios-shots/<device>/ for review.
enum UI {
    static let server = "192.168.178.120:8096"

    @MainActor
    static func launch(reset: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        if reset { app.launchArguments.append("-uiTestReset") }
        app.launch()
        return app
    }

    @MainActor
    static func signIn(_ app: XCUIApplication) {
        if app.tabBars.firstMatch.waitForExistence(timeout: 3) || app.buttons["tab.home"].exists { return }
        let address = app.textFields["server.address"]
        if address.waitForExistence(timeout: 5) {
            address.tap()
            address.typeText(server)
            app.buttons["server.connect"].tap()
        }
        let quickConnect = app.buttons["signin.quickconnect"]
        XCTAssertTrue(quickConnect.waitForExistence(timeout: 30), "sign-in screen")
        quickConnect.tap()
        let code = app.staticTexts["qc.code"]
        XCTAssertTrue(code.waitForExistence(timeout: 30), "Quick Connect code")
        announce(code.label)
        XCTAssertTrue(app.otherElements["home.hero"].waitForExistence(timeout: 90), "Home after approval")
    }

    /// Opens the first film among Home's poster cards (series pages are skipped) and returns its id
    /// and name.
    @MainActor
    static func openFirstFilm(_ app: XCUIApplication) -> (id: String, name: String) {
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 30), "Home cards")
        for index in 0..<min(cards.count, 8) {
            let card = cards.element(boundBy: index)
            let id = String(card.identifier.dropFirst("card.".count)), name = card.staticTexts.firstMatch.label
            card.tap()
            XCTAssertTrue(app.buttons["detail.play"].waitForExistence(timeout: 30), "detail page")
            if !app.buttons["series.seasons"].exists, !app.otherElements["series.seasons"].exists { return (id, name) }
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        XCTFail("no film on Home")
        return ("", "")
    }

    /// Finds an item through Search and opens its page.
    @MainActor
    static func openFromSearch(_ app: XCUIApplication, name: String, id: String) {
        tab(app, "Search")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(name)
        let card = app.buttons["card.\(id)"]
        XCTAssertTrue(card.waitForExistence(timeout: 20), "\(name) in Search")
        card.tap()
        XCTAssertTrue(app.buttons["detail.play"].waitForExistence(timeout: 30), "detail page")
    }

    /// Switches tab by its title, from the phone's tab bar or the iPad's top bar.
    @MainActor
    static func tab(_ app: XCUIApplication, _ title: String) {
        let inBar = app.tabBars.buttons[title]
        if inBar.exists { return inBar.tap() }
        let button = app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "tab \(title) among \(app.buttons.allElementsBoundByIndex.map(\.label))")
        button.tap()
    }

    /// Waits until `element`'s label is `label`.
    @MainActor
    static func waitForLabel(_ element: XCUIElement, _ label: String, timeout: Double = 20) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        return XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: timeout) == .completed
    }

    static func announce(_ code: String) {
        print("JFIOS-QC-CODE=\(code)")
        try? code.write(toFile: "/tmp/jfios-qc-code", atomically: true, encoding: .utf8)
    }

    @MainActor
    static func shot(_ name: String, _ test: XCTestCase) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "device"
        let folder = "/tmp/jfios-shots/\(device)"
        try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        try? screenshot.pngRepresentation.write(to: URL(filePath: "\(folder)/\(name).png"))
    }
}
