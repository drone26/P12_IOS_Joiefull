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

        let thirdStar = app.buttons["Noter 3 étoiles"]
        XCTAssertTrue(thirdStar.waitForExistence(timeout: 5))
        thirdStar.tap()

        let reviewField = app.textFields["Votre avis"]
        XCTAssertTrue(reviewField.exists)
        reviewField.tap()
        reviewField.typeText("Super article")

        app.navigationBars.buttons.firstMatch.tap()

        firstCard.tap()
        XCTAssertTrue(thirdStar.waitForExistence(timeout: 5))

        let starButtons = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Noter'"))
        XCTAssertEqual(starButtons.count, 5)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
