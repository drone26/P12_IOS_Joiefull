//
//  ClothingItem.swift
//  ClothingItem
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import Foundation

struct ClothingItem: Codable, Identifiable, nonisolated Hashable, Sendable {
    let id: Int
    let picture: Picture
    let name: String
    let category: Category
    let price: Double
    let originalPrice: Double



    enum CodingKeys: String, CodingKey {
        case id, picture, name, category, price
        case originalPrice = "original_price"
    }
}

struct Picture: Codable, nonisolated Hashable, Sendable {
    let url: URL
    let description: String
}

enum Category: String, Codable, Sendable, CaseIterable {
    case tops = "TOPS"
    case bottoms = "BOTTOMS"
    case shoes = "SHOES"
    case accessories = "ACCESSORIES"

    var displayName: String {
        switch self {
        case .tops: return "Hauts"
        case .bottoms: return "Bas"
        case .shoes: return "Chaussures"
        case .accessories: return "Accessoires"
        }
    }
}
