//
//  ReviewTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation
import Testing
@testable import Joiefull

@MainActor
struct ReviewTests {

    @Test func decode_fromAPIJSON_mapsSnakeCaseKeys() throws {
        let json = """
        {
            "id": 12,
            "clothing_id": 4,
            "user_id": 2,
            "text": "Très bien",
            "rating": 5
        }
        """.data(using: .utf8)!

        let review = try JSONDecoder().decode(Review.self, from: json)

        #expect(review.id == 12)
        #expect(review.clothingId == 4)
        #expect(review.userId == 2)
        #expect(review.text == "Très bien")
        #expect(review.rating == 5)
    }

    @Test func encode_usesSnakeCaseKeysOnTheWire() throws {
        let review = Review(id: 1, clothingId: 2, userId: 3, text: "ok", rating: 4)
        let data = try JSONEncoder().encode(review)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(object?["clothing_id"] as? Int == 2)
        #expect(object?["user_id"] as? Int == 3)
        #expect(object?["id"] as? Int == 1)
        #expect(object?["text"] as? String == "ok")
        #expect(object?["rating"] as? Int == 4)
        #expect(object?["clothingId"] == nil) // camelCase must not leak
        #expect(object?["userId"] == nil)
    }

    @Test func encode_decode_roundTrip_isLossless() throws {
        let original = Review(id: 99, clothingId: 7, userId: 1, text: "Top !", rating: 5)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Review.self, from: data)
        #expect(decoded == original)
    }

    @Test func decode_missingClothingId_fails() {
        let json = """
        { "id": 1, "user_id": 2, "text": "x", "rating": 5 }
        """.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Review.self, from: json)
        }
    }

    @Test func decode_missingUserId_fails() {
        let json = """
        { "id": 1, "clothing_id": 2, "text": "x", "rating": 5 }
        """.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Review.self, from: json)
        }
    }

    @Test func identifiable_idMatchesReviewId() {
        let review = Review(id: 7, clothingId: 1, userId: 1, text: "", rating: 3)
        #expect(review.id == 7)
    }

    @Test func equatableAndHashable_distinguishDifferentValues() {
        let a = Review(id: 1, clothingId: 2, userId: 3, text: "x", rating: 4)
        let b = Review(id: 1, clothingId: 2, userId: 3, text: "x", rating: 4)
        let c = Review(id: 1, clothingId: 2, userId: 3, text: "x", rating: 5)
        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }
}
