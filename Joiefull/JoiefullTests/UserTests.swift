//
//  UserTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation
import Testing
@testable import Joiefull

@MainActor
struct UserTests {

    @Test func decode_fromAPIJSON_mapsSnakeCaseKeys() throws {
        let json = """
        {
            "id": 1,
            "first_name": "Mathieu",
            "last_name": "ARRIO",
            "email": "claudeai3818@arrio.fr",
            "avatar_url": "https://example.com/avatar.jpg"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)

        #expect(user.id == 1)
        #expect(user.firstName == "Mathieu")
        #expect(user.lastName == "ARRIO")
        #expect(user.email == "claudeai3818@arrio.fr")
        #expect(user.avatarURL == URL(string: "https://example.com/avatar.jpg"))
    }

    @Test func decode_withNullAvatarURL_yieldsNil() throws {
        let json = """
        {
            "id": 2,
            "first_name": "Marie",
            "last_name": "Dupont",
            "email": "m@example.com",
            "avatar_url": null
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)

        #expect(user.avatarURL == nil)
    }

    @Test func decode_withMissingAvatarURL_yieldsNil() throws {
        let json = """
        {
            "id": 3,
            "first_name": "Julien",
            "last_name": "Martin",
            "email": "j@example.com"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)

        #expect(user.avatarURL == nil)
    }

    @Test func encode_usesSnakeCaseKeys() throws {
        let user = User(
            id: 1,
            firstName: "First",
            lastName: "Last",
            email: "e@example.com",
            avatarURL: URL(string: "https://example.com/a.jpg")
        )
        let data = try JSONEncoder().encode(user)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(object?["first_name"] as? String == "First")
        #expect(object?["last_name"] as? String == "Last")
        #expect(object?["avatar_url"] as? String == "https://example.com/a.jpg")
        #expect(object?["firstName"] == nil)
        #expect(object?["lastName"] == nil)
    }

    @Test func encode_decode_roundTrip_isLossless() throws {
        let original = User(
            id: 5,
            firstName: "Camille",
            lastName: "Petit",
            email: "c@example.com",
            avatarURL: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(User.self, from: data)
        #expect(decoded == original)
    }

    @Test func fullName_concatenatesFirstAndLastWithSpace() {
        let user = User(id: 1, firstName: "Marie", lastName: "Dupont", email: "x", avatarURL: nil)
        #expect(user.fullName == "Marie Dupont")
    }

    @Test func fullName_handlesEmptyComponents() {
        let onlyFirst = User(id: 1, firstName: "Marie", lastName: "", email: "x", avatarURL: nil)
        let onlyLast = User(id: 1, firstName: "", lastName: "Dupont", email: "x", avatarURL: nil)
        let empty = User(id: 1, firstName: "", lastName: "", email: "x", avatarURL: nil)

        #expect(onlyFirst.fullName == "Marie ")
        #expect(onlyLast.fullName == " Dupont")
        #expect(empty.fullName == " ")
    }

    @Test func equatableAndHashable() {
        let a = User(id: 1, firstName: "A", lastName: "B", email: "x", avatarURL: nil)
        let b = User(id: 1, firstName: "A", lastName: "B", email: "x", avatarURL: nil)
        let c = User(id: 2, firstName: "A", lastName: "B", email: "x", avatarURL: nil)

        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }
}
