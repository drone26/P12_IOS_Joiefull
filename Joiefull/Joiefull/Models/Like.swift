//
//  Like.swift
//  Like
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import Foundation

struct Like: Codable, Identifiable, Sendable, Equatable {
    let id: Int
    let clothingId: Int
    let userId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case clothingId = "clothing_id"
        case userId = "user_id"
    }
}
