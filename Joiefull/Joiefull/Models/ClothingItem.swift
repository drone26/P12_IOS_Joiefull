//
//  ClothingCardView.swift
//  ClothingCardView
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import Foundation

nonisolated struct ClothingItem: Codable, Identifiable, nonisolated Hashable, Sendable {
    let id: Int
    let picture: Picture
    let name: String
    let category: Category
    let likes: Int
    let price: Double
    let originalPrice: Double

    var rating: Double {
        let seed = Double((id * 17 + 13) % 20)
        return (30.0 + seed) / 10.0
    }

    enum CodingKeys: String, CodingKey {
        case id, picture, name, category, likes, price
        case originalPrice = "original_price"
    }
}

nonisolated struct Picture: Codable, nonisolated Hashable, Sendable {
    let url: URL
    let description: String
}

nonisolated enum Category: String, Codable, Sendable, CaseIterable {
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
