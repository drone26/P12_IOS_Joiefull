//
//  View+Accessibility.swift
//  View+Accessibility
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import SwiftUI

extension View {
    /// Adds an accessibility label tagged with the French language so VoiceOver
    /// pronounces it with the French voice regardless of the system language.
    func frAccessibilityLabel(_ text: String) -> some View {
        accessibilityLabel(Text(frenchAttributed(text)))
    }

    /// Adds an accessibility value tagged with the French language.
    func frAccessibilityValue(_ text: String) -> some View {
        accessibilityValue(Text(frenchAttributed(text)))
    }

    /// Adds an accessibility hint tagged with the French language.
    func frAccessibilityHint(_ text: String) -> some View {
        accessibilityHint(Text(frenchAttributed(text)))
    }
}

func frenchAttributed(_ string: String) -> AttributedString {
    var attr = AttributedString(string)
    attr.languageIdentifier = "fr-FR"
    return attr
}
