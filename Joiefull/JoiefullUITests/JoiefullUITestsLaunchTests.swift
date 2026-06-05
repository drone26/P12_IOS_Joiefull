//
//  JoiefullUITestsLaunchTests.swift
//  JoiefullUITests
//
//  Created by Mathieu ARRIO on 12/05/2026.
//

import XCTest

final class JoiefullUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        let testOrientation = ProcessInfo.processInfo.environment["TEST_ORIENTATION"] ?? "portrait"
        XCUIDevice.shared.orientation = (testOrientation == "landscape") ? .landscapeLeft : .portrait
    }

    @MainActor
    func testLaunch() throws {
        // Given
        let app = XCUIApplication()
        // When
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
