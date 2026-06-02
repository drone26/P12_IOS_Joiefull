//
//  ContentViewUITests.swift
//  JoiefullUITests
//
//  Created by Mathieu ARRIO on 02/06/2026.
//

import XCTest

final class ContentViewUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        let testOrientation = ProcessInfo.processInfo.environment["TEST_ORIENTATION"] ?? "portrait"
        XCUIDevice.shared.orientation = (testOrientation == "landscape") ? .landscapeLeft : .portrait
        
        app.launch()
    }

    @MainActor
    func testContentView_showsJoiefullTitle_andCatalog() {
        // Verify the navigation title is present
        let navBarTitle = app.navigationBars["Joiefull"]
        // In SwiftUI, navigation titles on macOS/iPad might appear as static texts if they aren't in a standard nav bar,
        // but typically they are in navigationBars or staticTexts
        let titleExists = navBarTitle.exists || app.staticTexts["Joiefull"].exists
        XCTAssertTrue(titleExists, "The ContentView should display the 'Joiefull' title")
        
        // Verify that the CatalogView is rendered by looking for a category header
        let hautsCategory = app.staticTexts["Hauts"]
        XCTAssertTrue(hautsCategory.waitForExistence(timeout: 10), "The CatalogView should be visible within ContentView")
    }
    
    @MainActor
    func testContentView_navigatesToDetailView_whenItemIsTapped() {
        // Find the first clothing item card
        let firstCard = app.buttons.firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        
        // Tap it
        firstCard.tap()
        
        // Verify that the detail view is presented (we can look for the share button or rating stars)
        let shareButton = app.buttons["Partager cet article"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Detail view should be presented after tapping an item")
        
        // On iPad, both catalog and detail are visible. On iPhone, only detail is visible.
        // ContentView handles this routing. If we can see the share button, ContentView did its job!
    }

    @MainActor
    func testContentView_tabletLayout_displaysDetailAndRefreshes_whenSwitchingItems() {
        // This test is particularly useful for iPad layout (tabletLayout) where selecting a new item
        // replaces the detail view, triggering onDisappear and the onSubmit closure (lines 38-47).
        
        // Find the first and second cards
        let buttons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'noté'"))
        XCTAssertTrue(buttons.count >= 2, "There should be at least two items in the catalog")
        
        let firstCard = buttons.element(boundBy: 0)
        let secondCard = buttons.element(boundBy: 1)
        
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        firstCard.tap()
        
        let shareButton = app.buttons["Partager cet article"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
        
        // If we are on iPad, we can tap the second card while the first detail is open
        if UIDevice.current.userInterfaceIdiom == .pad {
            secondCard.tap()
            XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
        } else {
            // On iPhone, we need to go back first
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                XCTAssertTrue(secondCard.waitForExistence(timeout: 5))
                secondCard.tap()
                XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
            }
        }
    }
}
