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
