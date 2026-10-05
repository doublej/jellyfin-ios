import XCTest

/// Watched and favourite flip on the page and stay flipped when the page is opened again from Search.
/// Un-marking watched brings the resume point back. Restore with `scripts/watch-state.sh restore`.
final class ToggleTests: XCTestCase {
    @MainActor
    func testWatchedAndFavourite() {
        let app = UI.launch()
        UI.signIn(app)
        let film = UI.openFirstFilm(app)
        let favorite = app.buttons["toggle.favorite"], played = app.buttons["toggle.played"], play = app.buttons["detail.play"]
        let favoriteBefore = favorite.label, playedBefore = played.label, playBefore = play.label

        favorite.tap()
        XCTAssertTrue(UI.waitForLabel(favorite, favoriteBefore == "Add to favourites" ? "Remove from favourites" : "Add to favourites"))
        played.tap()
        XCTAssertTrue(UI.waitForLabel(played, playedBefore == "Mark as watched" ? "Mark as unwatched" : "Mark as watched"))
        UI.shot("20-toggled", self)

        UI.openFromSearch(app, name: film.name, id: film.id)
        XCTAssertNotEqual(app.buttons["toggle.favorite"].label, favoriteBefore, "favourite kept after reopening")
        XCTAssertNotEqual(app.buttons["toggle.played"].label, playedBefore, "watched kept after reopening")

        app.buttons["toggle.favorite"].tap()
        app.buttons["toggle.played"].tap()
        XCTAssertTrue(UI.waitForLabel(app.buttons["toggle.favorite"], favoriteBefore))
        XCTAssertTrue(UI.waitForLabel(app.buttons["toggle.played"], playedBefore))
        XCTAssertTrue(UI.waitForLabel(app.buttons["detail.play"], playBefore), "resume point back after un-marking")
    }
}
