import XCTest

/// Downloads an Everwood episode at 1.5 Mbps, follows the progress, plays the file and jumps to 50%.
/// A downloaded file keeps its position on the device and sends it to the server afterwards: check with
/// `scripts/watch-state.sh diff`, then `restore`. Takes as long as the server's conversion (about 10 minutes).
final class DownloadTests: XCTestCase {
    @MainActor
    func testDownloadPlayAndSync() {
        let app = UI.launch()
        UI.signIn(app)
        openEpisode(app)
        app.buttons["detail.download"].tap()
        app.buttons["1.5 Mbps"].tap()

        UI.tab(app, "Downloads")
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'download.'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        sleep(20)
        UI.shot("62-download-progress", self)
        let done = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == 'done'"), object: row)
        XCTAssertEqual(XCTWaiter.wait(for: [done], timeout: 1800), .completed, "download finished")
        UI.shot("63-download-done", self)

        row.tap()
        XCTAssertTrue(UI.waitForLabel(app.buttons["player.toggle"], "Pause", timeout: 30), "plays the file")
        app.typeKey("5", modifierFlags: [])
        sleep(4)
        if !app.buttons["player.close"].isHittable { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap() }
        app.buttons["player.close"].tap()
    }

    /// Search → the series → the first episode's page.
    @MainActor
    private func openEpisode(_ app: XCUIApplication) {
        UI.tab(app, "Search")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Everwood")
        let series = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label CONTAINS 'Everwood'")).firstMatch
        XCTAssertTrue(series.waitForExistence(timeout: 20))
        series.tap()
        let episode = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'episode.'")).firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 30))
        episode.tap()
        XCTAssertTrue(app.buttons["detail.download"].waitForExistence(timeout: 30))
    }
}
