//
//  Review+Average.swift
//  Review+Average
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation

extension Array where Element == Review {
    func averagesByClothingID() -> [Int: Double] {
        Dictionary(grouping: self, by: \.clothingId).mapValues { reviews in
            let sum = reviews.reduce(0) { $0 + $1.rating }
            return Double(sum) / Double(reviews.count)
        }
    }
}
