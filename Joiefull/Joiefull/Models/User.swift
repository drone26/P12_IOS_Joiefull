//
//  User.swift
//  User
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation

nonisolated struct User: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let avatarURL: URL?

    var fullName: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarURL = "avatar_url"
    }
}
