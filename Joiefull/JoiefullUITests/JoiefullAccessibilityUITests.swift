//
//  JoiefullAccessibilityUITests.swift
//  JoiefullUITests
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import XCTest

final class JoiefullAccessibilityUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set orientation before launching
        let testOrientation = ProcessInfo.processInfo.environment["TEST_ORIENTATION"] ?? "portrait"
        XCUIDevice.shared.orientation = (testOrientation == "landscape") ? .landscapeLeft : .portrait
        
        app.launch()
    }

    // MARK: - Catalog

    @MainActor
    func testCatalog_categoryHeaders_areExposed() {
        let hauts = app.staticTexts["Hauts"]
        XCTAssertTrue(hauts.waitForExistence(timeout: 10), "Category heading 'Hauts' should be in the accessibility tree")
        XCTAssertTrue(app.staticTexts["Bas"].exists)
        XCTAssertTrue(app.staticTexts["Chaussures"].exists)
        XCTAssertTrue(app.staticTexts["Accessoires"].exists)
    }

    @MainActor
    func testCatalog_card_isSingleAccessibleButton_withCombinedLabel() {
        let firstCard = app.buttons.firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))

        let label = firstCard.label
        XCTAssertTrue(label.contains("noté"), "Card label should include rating, got: \(label)")
        XCTAssertTrue(label.contains("prix"), "Card label should include price, got: \(label)")
        XCTAssertTrue(label.contains("aime"), "Card label should include likes, got: \(label)")
    }

    // MARK: - Detail

    @MainActor
    func testDetail_shareButton_isLabeledInFrench() {
        openFirstDetail()

        let share = app.buttons["Partager cet article"]
        XCTAssertTrue(share.waitForExistence(timeout: 5), "Share button should be labeled 'Partager cet article'")
    }

    @MainActor
    func testDetail_shareCommentSheet_hasAccessibleElements() {
        openFirstDetail()
        
        let share = app.buttons["Partager cet article"]
        XCTAssertTrue(share.waitForExistence(timeout: 5))
        share.tap()
        
        // Test custom comment field accessibility
        // Note: Finding text fields with vertical axis can be tricky in XCTest, so we use a generic descendant lookup
        let field = app.descendants(matching: .any)["Commentaire personnalisé pour le partage"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Comment field should have correct French accessibility label")
        
        // Note: UI tests can sometimes struggle reading accessibility hints directly, but we can verify the button labels
        let continueButton = app.buttons["Continuer le partage"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Continue button should be present")
        
        let cancelButton = app.buttons["Annuler le partage"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Cancel button should have 'Annuler le partage' label")
    }

    @MainActor
    func testDetail_likesBadge_isAnnouncedInFrench() {
        openFirstDetail()

        let predicate = NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", "aime", "favoris")
        let likes = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(likes.waitForExistence(timeout: 5), "Likes badge should expose a label containing 'aime' and 'favoris'")
    }

    @MainActor
    func testDetail_averageRating_hasFrenchAccessibilityLabel() {
        openFirstDetail()

        let predicate = NSPredicate(format: "label BEGINSWITH %@", "Note moyenne")
        let avg = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(avg.waitForExistence(timeout: 5), "Average rating should be labeled 'Note moyenne X.X sur 5'")
    }

    @MainActor
    func testDetail_starButtons_areIndividuallyAccessible() {
        openFirstDetail()

        for star in 1...5 {
            let plural = star > 1 ? "s" : ""
            let expected = "Noter \(star) étoile\(plural)"
            let button = app.buttons[expected]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing accessible star button '\(expected)'")
        }
    }

    @MainActor
    func testDetail_starButton_tapMarksAsSelected() {
        openFirstDetail()

        let third = app.buttons["Noter 3 étoiles"]
        XCTAssertTrue(third.waitForExistence(timeout: 5))
        third.tap()

        XCTAssertTrue(third.isSelected, "After tap, the chosen star button should report isSelected=true")
    }

    @MainActor
    func testDetail_reviewField_hasFrenchLabel() {
        openFirstDetail()

        let field = app.textFields["Votre avis"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Review text field should be labeled 'Votre avis'")
    }

    @MainActor
    func testDetail_reviewsHeader_isExposed() {
        openFirstDetail()

        let predicate = NSPredicate(format: "label BEGINSWITH 'Avis ('")
        let header = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Reviews section heading 'Avis (N)' should exist")
    }

    @MainActor
    func testDetail_image_exposesFrenchPictureDescription() {
        openFirstDetail()

        // The first TOPS card is "Blazer marron". Its picture description
        // ("Homme en costume et veste de blazer…") is exposed both as the
        // image's accessibility label and as a description text.
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", "costume et veste de blazer")
        let described = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(described.waitForExistence(timeout: 5),
                      "Picture description should be exposed to VoiceOver in the detail view")
    }

    @MainActor
    func testDetail_productName_isExposedAsAccessibleText() {
        openFirstDetail()

        let name = app.staticTexts["Blazer marron"]
        XCTAssertTrue(name.waitForExistence(timeout: 5),
                      "Product name should be exposed to VoiceOver as accessible text")
    }

    @MainActor
    func testDetail_reviewField_exposesFrenchPlaceholder() {
        openFirstDetail()

        let field = app.textFields["Votre avis"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        let placeholder = field.placeholderValue ?? ""
        XCTAssertTrue(placeholder.contains("Partagez"),
                      "Review field should expose a French placeholder, got: '\(placeholder)'")
    }

    @MainActor
    func testDetail_starButtons_initiallyNoneSelected() {
        openFirstDetail()

        for star in 1...5 {
            let plural = star > 1 ? "s" : ""
            let button = app.buttons["Noter \(star) étoile\(plural)"]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            XCTAssertFalse(button.isSelected,
                           "Star \(star) should not be selected before the user taps any rating")
        }
    }

    @MainActor
    func testDetail_starButton_selectionMovesBetweenStars() {
        openFirstDetail()

        let second = app.buttons["Noter 2 étoiles"]
        let fourth = app.buttons["Noter 4 étoiles"]
        XCTAssertTrue(second.waitForExistence(timeout: 5))

        second.tap()
        XCTAssertTrue(second.isSelected, "Second star should be selected after the first tap")

        fourth.tap()
        XCTAssertTrue(fourth.isSelected, "Tapping a different star should mark it as selected")
        XCTAssertFalse(second.isSelected,
                       "Previously selected star should report isSelected=false after another star is tapped")
    }

    @MainActor
    func testDetail_originalPrice_hasFrenchAccessibilityLabel_whenDiscounted() {
        // "Pull vert femme" is discounted (29.99 vs 39.99) and exposes
        // an "Ancien prix …" accessibility label for VoiceOver.
        openCard(labelContaining: "Pull vert femme")

        let predicate = NSPredicate(format: "label BEGINSWITH %@", "Ancien prix")
        let oldPrice = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(oldPrice.waitForExistence(timeout: 5),
                      "Discounted item should expose an 'Ancien prix' accessibility label")
    }

    @MainActor
    func testDetail_reviewRow_hasCombinedFrenchAccessibilityLabel() {
        openFirstDetail()

        // Each review row uses `.accessibilityElement(children: .ignore)` and
        // is announced as "<author>, X étoile[s] sur 5. <text>".
        let predicate = NSPredicate(
            format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@",
            "étoile", "sur 5"
        )
        let review = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 10),
                      "Review row should be exposed as a single VoiceOver element combining author, rating and text")
    }

    // MARK: - Helpers

    @MainActor
    private func openFirstDetail() {
        let firstCard = app.buttons.firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        firstCard.tap()
    }

    @MainActor
    private func openCard(labelContaining text: String) {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let card = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10),
                      "Could not find a card whose label contains '\(text)'")
        card.tap()
    }
}
