//
//  ViewAccessibilityTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 02/06/2026.
//

import Testing
import Foundation
import SwiftUI
@testable import Joiefull

struct ViewAccessibilityTests {

    @Test func frenchAttributed_addsFrenchLanguageIdentifier() {
        let text = "Bonjour"
        let attr = frenchAttributed(text)
        
        #expect(attr.languageIdentifier == "fr-FR")
        #expect(String(attr.characters) == text)
    }

    @Test func frAccessibilityValue_appliesFrenchModifier() {
        // Without ViewInspector, we cannot easily introspect the deep accessibility traits of a SwiftUI view.
        // We verify that the function compiles and produces a valid modified view without crashing.
        let view = Text("Test").frAccessibilityValue("Une valeur")
        
        let stringDesc = String(describing: view)
        #expect(stringDesc.contains("AccessibilityAttachmentModifier"))
    }
    
    @Test func frAccessibilityLabel_appliesFrenchModifier() {
        let view = Text("Test").frAccessibilityLabel("Un label")
        
        let stringDesc = String(describing: view)
        #expect(stringDesc.contains("AccessibilityAttachmentModifier"))
    }
    
    @Test func frAccessibilityHint_appliesFrenchModifier() {
        let view = Text("Test").frAccessibilityHint("Un indice")
        
        let stringDesc = String(describing: view)
        #expect(stringDesc.contains("AccessibilityAttachmentModifier"))
    }
}

