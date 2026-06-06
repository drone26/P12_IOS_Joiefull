//
//  FavoritesUITests.swift
//  FavoritesUITests
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import XCTest

final class FavoritesUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-resetFavorites")
        
        let testOrientation = ProcessInfo.processInfo.environment["TEST_ORIENTATION"] ?? "portrait"
        XCUIDevice.shared.orientation = (testOrientation == "landscape") ? .landscapeLeft : .portrait
        
        app.launch()
    }

    @MainActor
    func testFavorites_canAddAndRemoveFromCatalog() {
        // Given
        // When
        let firstCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'noté'")).firstMatch
        // Then
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        
        firstCard.tap()
        
        let detailFavoriteButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Ajouter aux favoris'")).firstMatch
        XCTAssertTrue(detailFavoriteButton.waitForExistence(timeout: 5))

        
        detailFavoriteButton.tap()
        
        let detailRemoveButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Retirer des favoris'")).firstMatch
        XCTAssertTrue(detailRemoveButton.waitForExistence(timeout: 5))
        
        // Remove it
        detailRemoveButton.tap()
        
        XCTAssertTrue(detailFavoriteButton.waitForExistence(timeout: 5))
    }
}
