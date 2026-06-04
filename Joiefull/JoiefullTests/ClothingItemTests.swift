//
//  ClothingItemTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation
import Testing
@testable import Joiefull

struct ClothingItemTests {

    @Test func decode_fromAPIJSON_mapsSnakeCaseKeys() throws {
        let json = """
        {
            "id": 7,
            "picture": {
                "url": "https://example.com/p.jpg",
                "description": "Photo"
            },
            "name": "Bomber",
            "category": "TOPS",
            "price": 89.99,
            "original_price": 109.99
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(ClothingItem.self, from: json)

        #expect(item.id == 7)
        #expect(item.name == "Bomber")
        #expect(item.category == .tops)
        #expect(item.price == 89.99)
        #expect(item.originalPrice == 109.99)
        #expect(item.picture.url == URL(string: "https://example.com/p.jpg"))
        #expect(item.picture.description == "Photo")
    }

    @Test func encode_decode_roundTrip_isLossless() throws {
        let original = ClothingItem(
            id: 42,
            picture: Picture(url: URL(string: "https://example.com/x.jpg")!, description: "x"),
            name: "Item",
            category: .accessories,
            price: 19.99,
            originalPrice: 29.99
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClothingItem.self, from: data)

        #expect(decoded == original)
    }

    @Test func rating_computation_isDeterministicForGivenID() {
        let item0 = makeItem(id: 0)
        let item1 = makeItem(id: 1)
        let item11 = makeItem(id: 11)

        // (id * 17 + 13) % 20 + 30 / 10
        #expect(item0.rating == 4.3)  // 13 % 20 = 13 -> (30+13)/10
        #expect(item1.rating == 4.0)  // 30 % 20 = 10 -> (30+10)/10
        #expect(item11.rating == 3.0) // 200 % 20 = 0 -> (30+0)/10
    }

    @Test func rating_isAlwaysBetween3And4Point9() {
        for id in 0..<200 {
            let rating = makeItem(id: id).rating
            #expect(rating >= 3.0)
            #expect(rating <= 4.9)
        }
    }

    @Test func equatable_and_hashable_areBasedOnAllFields() {
        let a = makeItem(id: 1)
        let b = makeItem(id: 1)
        let c = makeItem(id: 2)

        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }

    @Test(arguments: zip(Joiefull.Category.allCases, ["Hauts", "Bas", "Chaussures", "Accessoires"]))
    func category_displayName_isLocalizedFrench(category: Joiefull.Category, expected: String) {
        #expect(category.displayName == expected)
    }

    @Test func category_rawValues_matchAPIContract() {
        #expect(Joiefull.Category.tops.rawValue == "TOPS")
        #expect(Joiefull.Category.bottoms.rawValue == "BOTTOMS")
        #expect(Joiefull.Category.shoes.rawValue == "SHOES")
        #expect(Joiefull.Category.accessories.rawValue == "ACCESSORIES")
    }

    @Test func category_allCases_containsAllFourValues() {
        #expect(Joiefull.Category.allCases.count == 4)
        #expect(Set(Joiefull.Category.allCases) == [.tops, .bottoms, .shoes, .accessories])
    }

    @Test func category_decoding_unknownValue_fails() {
        let data = "\"UNKNOWN\"".data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Joiefull.Category.self, from: data)
        }
    }

    @Test func picture_decode_nonStringURL_fails() {
        let badJson = """
        { "url": 42, "description": "x" }
        """.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Picture.self, from: badJson)
        }
    }

    @Test func picture_decode_missingDescription_fails() {
        let json = """
        { "url": "https://example.com/a.jpg" }
        """.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Picture.self, from: json)
        }
    }

    // MARK: - Helpers

    private func makeItem(id: Int) -> ClothingItem {
        ClothingItem(
            id: id,
            picture: Picture(url: URL(string: "https://example.com/\(id).jpg")!, description: "d"),
            name: "name",
            category: .tops,
            price: 0,
            originalPrice: 0
        )
    }
}
