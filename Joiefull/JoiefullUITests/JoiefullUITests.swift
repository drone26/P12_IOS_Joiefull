//
//  JoiefullUITests.swift
//  JoiefullUITests
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import XCTest

final class JoiefullUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Set orientation for the tests
        let testOrientation = ProcessInfo.processInfo.environment["TEST_ORIENTATION"] ?? "portrait"
        XCUIDevice.shared.orientation = (testOrientation == "landscape") ? .landscapeLeft : .portrait
    }

    @MainActor
    func testRatingFlow() throws {
        // Given
        let app = XCUIApplication()
        // When
        app.launch()

        let firstCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'noté'")).firstMatch
        // Then
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        firstCard.tap()

        let thirdStar = app.buttons["Noter 3 étoiles"]
        XCTAssertTrue(thirdStar.waitForExistence(timeout: 5))
        thirdStar.tap()

        let reviewField = app.textFields["Votre avis"]
        XCTAssertTrue(reviewField.exists)
        reviewField.tap()
        reviewField.typeText("Super article")

        if UIDevice.current.userInterfaceIdiom != .pad {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }

        firstCard.tap()
        XCTAssertTrue(thirdStar.waitForExistence(timeout: 5))

        let starButtons = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Noter'"))
        XCTAssertEqual(starButtons.count, 5)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // Given
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
