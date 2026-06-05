//
//  JoiefullApp.swift
//  JoiefullApp
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import SwiftUI

@main
struct JoiefullApp: App {
    init() {
        UITextField.appearance().adjustsFontForContentSizeCategory = true
        UITextView.appearance().adjustsFontForContentSizeCategory = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
