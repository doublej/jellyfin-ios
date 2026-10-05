import XCTest

/// Home → a film's page → play → `3` jumps to 30% → close. The page then offers Resume and the film is
/// in Continue Watching. Run `scripts/watch-state.sh restore` afterwards to put the old state back.
final class PlaybackTests: XCTestCase {
    @MainActor
    func testHomeDetailPlayResume() {
        let app = UI.launch()
        UI.signIn(app)
        let film = UI.openFirstFilm(app)
        UI.shot("10-film", self)
        app.buttons["detail.play"].tap()

        let seek = app.sliders["player.seek"]
        XCTAssertTrue(seek.waitForExistence(timeout: 30), "player controls")
        XCTAssertTrue(app.buttons["player.toggle"].waitForExistence(timeout: 30))
        XCTAssertTrue(UI.waitForLabel(app.buttons["player.toggle"], "Pause", timeout: 40), "playing")
        app.typeKey("3", modifierFlags: [])  // the web client's keys: 3 jumps to 30%
        sleep(4)
        if !seek.isHittable { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap() }
        UI.shot("11-player", self)
        app.buttons["player.close"].tap()

        XCTAssertTrue(UI.waitForLabel(app.buttons["detail.play"], "Resume"), "detail offers Resume")
        UI.shot("12-resume", self)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["thumb.\(film.id)"].waitForExistence(timeout: 30), "in Continue Watching")
    }
}
