import XCTest

/// Signs in from scratch with Quick Connect, without a password ever being typed.
final class SignInTests: XCTestCase {
    @MainActor
    func testQuickConnectSignIn() {
        let app = UI.launch(reset: true)
        let address = app.textFields["server.address"]
        XCTAssertTrue(address.waitForExistence(timeout: 10))
        UI.shot("01-server", self)
        address.tap()
        address.typeText(UI.server)
        app.buttons["server.connect"].tap()
        XCTAssertTrue(app.buttons["signin.quickconnect"].waitForExistence(timeout: 30))
        UI.shot("02-signin", self)
        app.buttons["signin.quickconnect"].tap()
        let code = app.staticTexts["qc.code"]
        XCTAssertTrue(code.waitForExistence(timeout: 30))
        UI.shot("03-quickconnect", self)
        UI.announce(code.label)
        XCTAssertTrue(app.otherElements["home.hero"].waitForExistence(timeout: 90))
        UI.shot("04-home", self)
    }
}
