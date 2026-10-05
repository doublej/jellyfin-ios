import XCTest

/// Walks every screen and saves a screenshot of each to /tmp/jfios-shots/<device>/ for review.
/// It plays a film for a few seconds; `scripts/watch-state.sh restore` puts its position back.
final class ScreenTour: XCTestCase {
    @MainActor
    func testTour() {
        let app = UI.launch()
        UI.signIn(app)
        sleep(2)
        UI.shot("30-home", self)
        app.swipeUp()
        UI.shot("31-home-rows", self)
        app.swipeDown()
        film(app)
        library(app)
        series(app)
        search(app)
        UI.tab(app, "Downloads")
        UI.shot("61-downloads", self)
        settings(app)
    }

    /// Types a query, then closes the search so the tab bar comes back.
    @MainActor
    private func search(_ app: XCUIApplication) {
        UI.tab(app, "Search")
        let field = app.searchFields.firstMatch
        guard field.waitForExistence(timeout: 10) else { return UI.shot("60-search-no-field", self) }
        field.tap()
        field.typeText("the")
        sleep(3)
        UI.shot("60-search", self)
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        if app.buttons["Close"].exists { app.buttons["Close"].firstMatch.tap() }
    }

    @MainActor
    private func film(_ app: XCUIApplication) {
        _ = UI.openFirstFilm(app)
        sleep(2)
        UI.shot("32-film", self)
        app.swipeUp()
        UI.shot("33-film-more", self)
        let person = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'person.'")).firstMatch
        if person.waitForExistence(timeout: 5) {
            person.tap()
            sleep(3)
            UI.shot("34-person", self)
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        app.swipeDown()
        player(app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    @MainActor
    private func player(_ app: XCUIApplication) {
        app.buttons["detail.play"].tap()
        XCTAssertTrue(app.buttons["player.toggle"].waitForExistence(timeout: 40))
        _ = UI.waitForLabel(app.buttons["player.toggle"], "Pause", timeout: 40)
        sleep(3)
        if !app.buttons["player.close"].isHittable { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap() }
        UI.shot("35-player", self)
        for menu in ["player.tracks", "player.quality"] where app.buttons[menu].isHittable {
            app.buttons[menu].tap()
            sleep(1)
            UI.shot("36-\(menu)", self)
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()
            if !app.buttons["player.close"].isHittable { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap() }
        }
        app.buttons["player.close"].tap()
    }

    @MainActor
    private func library(_ app: XCUIApplication) {
        UI.tab(app, "Films")
        XCTAssertTrue(app.buttons["browse.sort"].waitForExistence(timeout: 20))
        sleep(2)
        UI.shot("40-library-grid", self)
        app.buttons["browse.sort"].tap()
        sleep(1)
        UI.shot("42-library-sort", self)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
        if let layout = toolbar(app, "browse.layout", labels: ["List", "Posters"]) {
            layout.tap()
            sleep(2)
            UI.shot("41-library-list", self)
            toolbar(app, "browse.layout", labels: ["List", "Posters"])?.tap()
        }
        if let filters = toolbar(app, "browse.filters", labels: ["Filters"]) {
            filters.tap()
            sleep(2)
            UI.shot("43-library-filters", self)
            app.buttons["filters.done"].tap()
        }
    }

    /// On iPad the system folds some toolbar buttons into its "More" overflow menu, where they keep
    /// their labels but lose their identifiers. Nil when the menu doesn't offer it.
    @MainActor
    private func toolbar(_ app: XCUIApplication, _ id: String, labels: [String]) -> XCUIElement? {
        let button = app.buttons[id]
        if button.waitForExistence(timeout: 2) { return button }
        app.buttons["More"].firstMatch.tap()
        let item = app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", labels)).firstMatch
        if item.waitForExistence(timeout: 5) { return item }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
        return nil
    }

    @MainActor
    private func series(_ app: XCUIApplication) {
        UI.tab(app, "Series")
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 20))
        card.tap()
        XCTAssertTrue(app.buttons["detail.play"].waitForExistence(timeout: 30))
        sleep(2)
        UI.shot("50-series", self)
        app.swipeUp()
        UI.shot("51-series-episodes", self)
        let episode = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'episode.'")).firstMatch
        guard episode.waitForExistence(timeout: 10) else { return XCTFail("episode list") }
        episode.tap()
        sleep(3)
        UI.shot("52-episode", self)
        let season = app.buttons["episode.season"]
        if season.waitForExistence(timeout: 5) {
            season.tap()
            sleep(3)
            UI.shot("53-season", self)
        }
    }

    @MainActor
    private func settings(_ app: XCUIApplication) {
        UI.tab(app, "Home")
        if app.buttons["home.settings"].waitForExistence(timeout: 5) { app.buttons["home.settings"].tap() } else { UI.tab(app, "Settings") }
        XCTAssertTrue(app.buttons["settings.signout"].waitForExistence(timeout: 20))
        UI.shot("70-settings", self)
        app.swipeUp()
        UI.shot("71-settings-more", self)
    }
}
