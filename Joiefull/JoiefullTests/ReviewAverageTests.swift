//
//  ReviewAverageTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation
import Testing
@testable import Joiefull

struct ReviewAverageTests {

    @Test func averagesByClothingID_onEmptyArray_returnsEmptyDictionary() {
        let reviews: [Review] = []
        #expect(reviews.averagesByClothingID().isEmpty)
    }

    @Test func averagesByClothingID_singleReview_returnsThatRating() {
        let reviews = [Review(id: 1, clothingId: 10, userId: 1, text: "", rating: 4)]
        let averages = reviews.averagesByClothingID()
        #expect(averages == [10: 4.0])
    }

    @Test func averagesByClothingID_groupsByClothingId_andAveragesEachGroup() {
        let reviews = [
            Review(id: 1, clothingId: 1, userId: 1, text: "", rating: 5),
            Review(id: 2, clothingId: 1, userId: 2, text: "", rating: 3),
            Review(id: 3, clothingId: 2, userId: 1, text: "", rating: 4),
        ]
        let averages = reviews.averagesByClothingID()
        #expect(averages[1] == 4.0)  // (5 + 3) / 2
        #expect(averages[2] == 4.0)  // 4 / 1
        #expect(averages.count == 2)
    }

    @Test func averagesByClothingID_handlesMultipleReviewsForSameClothing() {
        let reviews = (1...5).map { i in
            Review(id: i, clothingId: 7, userId: i, text: "", rating: i)
        }
        let averages = reviews.averagesByClothingID()
        // (1+2+3+4+5) / 5 = 3.0
        #expect(averages[7] == 3.0)
    }

    @Test func averagesByClothingID_doesNotMixDifferentClothes() {
        let reviews = [
            Review(id: 1, clothingId: 1, userId: 1, text: "", rating: 1),
            Review(id: 2, clothingId: 2, userId: 1, text: "", rating: 5),
        ]
        let averages = reviews.averagesByClothingID()
        #expect(averages[1] == 1.0)
        #expect(averages[2] == 5.0)
    }
}
