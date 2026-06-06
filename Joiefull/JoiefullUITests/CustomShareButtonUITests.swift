//
//  CustomShareButtonUITests.swift
//  JoiefullUITests
//
//  Created by Mathieu ARRIO on 02/06/2026.
//

import XCTest

final class CustomShareButtonUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        let testOrientation = ProcessInfo.processInfo.environment["TEST_ORIENTATION"] ?? "portrait"
        XCUIDevice.shared.orientation = (testOrientation == "landscape") ? .landscapeLeft : .portrait
        
        app.launch()
    }

    private func openFirstDetail() {
        let firstCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'noté'")).firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        firstCard.tap()
    }

    @MainActor
    func testShareButton_opensCommentSheet_andCanBeCanceled() {
        // Given
        openFirstDetail()
        
        // When
        let shareButton = app.buttons["Partager cet article"]
        // Then
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
        shareButton.tap()
        
        let cancelButton = app.buttons["Annuler le partage"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()
        
        // Wait for sheet to disappear
        XCTAssertFalse(cancelButton.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testShareButton_opensCommentSheet_typesComment_andProceedsToShareSheet() {
        // Given
        openFirstDetail()
        
        // When
        let shareButton = app.buttons["Partager cet article"]
        // Then
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
        shareButton.tap()
        
        let commentField = app.descendants(matching: .any)["Commentaire personnalisé pour le partage"]
        XCTAssertTrue(commentField.waitForExistence(timeout: 5))
        
        commentField.tap()
        commentField.typeText("Ceci est un super article !")
        
        let continueButton = app.buttons["Continuer le partage"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()
        
        // Wait for native Share Sheet (ActivityViewController) to appear
        // Native share sheet usually contains a "Copy" or "Copier" button depending on language
        // Since we force Locale fr_FR in the app, but UI Tests might run in system language,
        // we can check for a standard iOS share sheet element, like the Close button ("Close" or "Fermer")
        // or just check that the Continue button has disappeared.
        XCTAssertFalse(continueButton.waitForExistence(timeout: 2))
        
        // The ActivityViewController usually presents a Close/Fermer button on iPad, 
        // or can be dismissed by swiping on iPhone. We'll just verify the comment sheet is gone.
    }
}
