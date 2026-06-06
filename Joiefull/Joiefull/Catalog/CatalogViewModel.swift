//
//  CatalogViewModel.swift
//  CatalogViewModel
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import Foundation

@Observable
final class CatalogViewModel {
    private(set) var clothesByCategory: [Category: [ClothingItem]] = [:]
    private(set) var averagesByItemID: [Int: Double] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let clothesRepository: ClothesRepositoryProtocol
    private let reviewRepository: ReviewRepositoryProtocol

    init(
        clothesRepository: ClothesRepositoryProtocol = ClothesRepository.shared,
        reviewRepository: ReviewRepositoryProtocol = ReviewRepository.shared
    ) {
        self.clothesRepository = clothesRepository
        self.reviewRepository = reviewRepository
    }

    func averageRating(for item: ClothingItem) -> Double {
        averagesByItemID[item.id] ?? 0.0
    }

    func loadClothes() async {
        isLoading = true
        errorMessage = nil
        async let items = clothesRepository.fetchClothes()
        async let reviews = reviewRepository.fetchReviews()
        do {
            let fetchedItems = try await items
            clothesByCategory = Dictionary(grouping: fetchedItems, by: \.category)
        } catch {
            errorMessage = error.localizedDescription
        }
        if let fetchedReviews = try? await reviews {
            averagesByItemID = fetchedReviews.averagesByClothingID()
        }
        isLoading = false
    }

    func refreshAverages() async {
        if let fetchedReviews = try? await reviewRepository.fetchReviews() {
            averagesByItemID = fetchedReviews.averagesByClothingID()
        }
    }
}
