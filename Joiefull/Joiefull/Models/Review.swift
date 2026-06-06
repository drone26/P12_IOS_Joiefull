//
//  Review.swift
//  Review
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation

struct Review: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let clothingId: Int
    let userId: Int
    let text: String
    let rating: Int

    enum CodingKeys: String, CodingKey {
        case id, text, rating
        case clothingId = "clothing_id"
        case userId = "user_id"
    }
}
