import XCTest

final class JoiefullUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRatingFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let firstCard = app.buttons.firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        firstCard.tap()

        let thirdStar = app.buttons["3 étoiles"]
        XCTAssertTrue(thirdStar.waitForExistence(timeout: 5))
        thirdStar.tap()

        let reviewField = app.textFields["Partagez ici vos impressions sur cette pièce"]
        XCTAssertTrue(reviewField.exists)
        reviewField.tap()
        reviewField.typeText("Super article")

        app.navigationBars.buttons.firstMatch.tap()

        firstCard.tap()
        XCTAssertTrue(thirdStar.waitForExistence(timeout: 5))

        let starButtons = app.buttons.matching(NSPredicate(format: "label MATCHES '.*étoile.*'"))
        XCTAssertGreaterThan(starButtons.count, 0)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
