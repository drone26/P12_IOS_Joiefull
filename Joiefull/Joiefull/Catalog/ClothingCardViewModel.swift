//
//  ClothingCardViewModel.swift
//  Joiefull
//

import Foundation

struct ClothingCardViewModel {
    let item: ClothingItem
    let rating: Double
    let likesCount: Int
    let isLiked: Bool
    let toggleLike: () async -> Void
    
    var accessibilityDescription: String {
        let ratingText = String(format: "%.1f", rating)
        let priceText = item.price.formatted(.currency(code: "EUR"))
        var parts = [
            item.name,
            item.picture.description,
            "noté \(ratingText) sur 5",
            "prix \(priceText)"
        ]
        if item.originalPrice != item.price {
            parts.append("ancien prix \(item.originalPrice.formatted(.currency(code: "EUR")))")
        }
        if isLiked {
            parts.append("Favori")
        }
        parts.append("\(likesCount) jaime")
        return parts.joined(separator: ", ")
    }
    
    var formattedRating: String {
        rating.formatted(.number.precision(.fractionLength(1)))
    }
    
    var formattedPrice: String {
        item.price.formatted(.currency(code: "EUR"))
    }
    
    var formattedOriginalPrice: String? {
        item.originalPrice != item.price ? item.originalPrice.formatted(.currency(code: "EUR")) : nil
    }
}
