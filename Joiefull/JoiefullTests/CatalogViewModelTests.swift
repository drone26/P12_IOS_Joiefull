//
//  CatalogViewModelTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 01/06/2026.
//

import XCTest
@testable import Joiefull

// MARK: - Test fakes

private final class FakeClothesRepository: ClothesRepositoryProtocol, @unchecked Sendable {
    var result: Result<[ClothingItem], Error> = .success([])
    private(set) var fetchCount = 0

    func fetchClothes() async throws -> [ClothingItem] {
        fetchCount += 1
        return try result.get()
    }
}

private final class FakeReviewRepository: ReviewRepositoryProtocol, @unchecked Sendable {
    var result: Result<[Review], Error> = .success([])
    private(set) var upsertedReviews: [Review] = []
    private(set) var fetchCount = 0

    func fetchReviews() async throws -> [Review] {
        fetchCount += 1
        return try result.get()
    }

    func upsertReview(_ review: Review) async {
        upsertedReviews.append(review)
        if case .success(var reviews) = result {
            if let idx = reviews.firstIndex(where: {
                $0.clothingId == review.clothingId && $0.userId == review.userId
            }) {
                reviews[idx] = review
            } else {
                reviews.append(review)
            }
            result = .success(reviews)
        }
    }
}

// MARK: - Fixture builders

private func makeItem(
    id: Int,
    category: Joiefull.Category = .tops,
    name: String = "Item",
    price: Double = 10,
    originalPrice: Double = 10
) -> ClothingItem {
    ClothingItem(
        id: id,
        picture: Picture(url: URL(string: "https://example.com/\(id).jpg")!, description: "d\(id)"),
        name: name,
        category: category,
        price: price,
        originalPrice: originalPrice
    )
}

private func makeReview(
    id: Int = 1,
    clothingId: Int,
    userId: Int = 1,
    text: String = "ok",
    rating: Int = 5
) -> Review {
    Review(id: id, clothingId: clothingId, userId: userId, text: text, rating: rating)
}

// MARK: - Tests

@MainActor
final class CatalogViewModelTests: XCTestCase {

    // MARK: - Initial state

    func test_init_setsEmptyDefaultState() {
        // Given
        let viewModel = CatalogViewModel(
            clothesRepository: FakeClothesRepository(),
            reviewRepository: FakeReviewRepository()
        )
        // When

        // Then
        XCTAssertTrue(viewModel.clothesByCategory.isEmpty)
        XCTAssertTrue(viewModel.averagesByItemID.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - averageRating(for:)

    func test_averageRating_returnsFallbackFromItem_whenNoOverridePresent() {
        // Given
        let viewModel = CatalogViewModel(
            clothesRepository: FakeClothesRepository(),
            reviewRepository: FakeReviewRepository()
        )
        let item = makeItem(id: 0)
        // When

        // Then
        XCTAssertEqual(viewModel.averageRating(for: item), item.rating, accuracy: .ulpOfOne)
    }

    func test_averageRating_returnsAveragedValue_whenOverridePresent() async {
        // Given
        let clothes = FakeClothesRepository()
        clothes.result = .success([makeItem(id: 5)])
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 5, userId: 1, rating: 4),
            makeReview(id: 2, clothingId: 5, userId: 2, rating: 2)
        ])
        let viewModel = CatalogViewModel(clothesRepository: clothes, reviewRepository: reviews)

        // When
        await viewModel.loadClothes()

        // Then
        XCTAssertEqual(viewModel.averageRating(for: makeItem(id: 5)), 3.0, accuracy: .ulpOfOne)
    }

    // MARK: - loadClothes()

    func test_loadClothes_groupsItemsByCategory_onSuccess() async {
        // Given
        let clothes = FakeClothesRepository()
        clothes.result = .success([
            makeItem(id: 1, category: .tops),
            makeItem(id: 2, category: .tops),
            makeItem(id: 3, category: .shoes)
        ])
        let viewModel = CatalogViewModel(
            clothesRepository: clothes,
            reviewRepository: FakeReviewRepository()
        )

        // When
        await viewModel.loadClothes()

        // Then
        XCTAssertEqual(viewModel.clothesByCategory[.tops]?.count, 2)
        XCTAssertEqual(viewModel.clothesByCategory[.shoes]?.count, 1)
        XCTAssertNil(viewModel.clothesByCategory[.bottoms])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_loadClothes_setsErrorMessage_whenClothesFetchFails() async {
        // Given
        let clothes = FakeClothesRepository()
        clothes.result = .failure(APIError.networkError)
        let viewModel = CatalogViewModel(
            clothesRepository: clothes,
            reviewRepository: FakeReviewRepository()
        )

        // When
        await viewModel.loadClothes()

        // Then
        XCTAssertEqual(viewModel.errorMessage, APIError.networkError.errorDescription)
        XCTAssertTrue(viewModel.clothesByCategory.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_loadClothes_ignoresReviewFailure_andKeepsClothesLoaded() async {
        // Given
        let clothes = FakeClothesRepository()
        clothes.result = .success([makeItem(id: 1, category: .tops)])
        let reviews = FakeReviewRepository()
        reviews.result = .failure(APIError.networkError)
        let viewModel = CatalogViewModel(clothesRepository: clothes, reviewRepository: reviews)

        // When
        await viewModel.loadClothes()

        // Then
        XCTAssertEqual(viewModel.clothesByCategory[.tops]?.count, 1)
        XCTAssertNil(viewModel.errorMessage, "Review failure should not surface as an error when clothes load successfully")
        XCTAssertTrue(viewModel.averagesByItemID.isEmpty)
    }

    func test_loadClothes_populatesAveragesByItemID_fromReviews() async {
        // Given
        let clothes = FakeClothesRepository()
        clothes.result = .success([makeItem(id: 7)])
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 7, userId: 1, rating: 5),
            makeReview(id: 2, clothingId: 7, userId: 2, rating: 3)
        ])
        let viewModel = CatalogViewModel(clothesRepository: clothes, reviewRepository: reviews)

        // When
        await viewModel.loadClothes()

        // Then
        XCTAssertEqual(viewModel.averagesByItemID[7]!, 4.0, accuracy: .ulpOfOne)
    }

    func test_loadClothes_resetsLoadingAndClearsPreviousErrorOnSecondCall() async {
        // Given
        let clothes = FakeClothesRepository()
        clothes.result = .failure(APIError.networkError)
        let viewModel = CatalogViewModel(
            clothesRepository: clothes,
            reviewRepository: FakeReviewRepository()
        )

        // When
        await viewModel.loadClothes()
        // Then
        XCTAssertNotNil(viewModel.errorMessage)

        clothes.result = .success([makeItem(id: 1, category: .bottoms)])
        await viewModel.loadClothes()

        XCTAssertNil(viewModel.errorMessage, "errorMessage should be cleared on a fresh successful load")
        XCTAssertEqual(viewModel.clothesByCategory[.bottoms]?.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - refreshAverages()

    func test_refreshAverages_replacesAverages_onSuccess() async {
        // Given
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 1, userId: 1, rating: 5),
            makeReview(id: 2, clothingId: 1, userId: 2, rating: 3)
        ])
        let viewModel = CatalogViewModel(
            clothesRepository: FakeClothesRepository(),
            reviewRepository: reviews
        )
        // When
        await viewModel.loadClothes()
        // Then
        XCTAssertEqual(viewModel.averagesByItemID[1]!, 4.0, accuracy: .ulpOfOne)

        reviews.result = .success([makeReview(id: 3, clothingId: 2, userId: 1, rating: 4)])
        await viewModel.refreshAverages()

        XCTAssertEqual(viewModel.averagesByItemID[2]!, 4.0, accuracy: .ulpOfOne)
        XCTAssertNil(viewModel.averagesByItemID[1],
                     "Averages should be replaced wholesale, not merged")
    }

    func test_refreshAverages_keepsExistingAverages_whenFetchFails() async {
        // Given
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 1, userId: 1, rating: 5)
        ])
        let viewModel = CatalogViewModel(
            clothesRepository: FakeClothesRepository(),
            reviewRepository: reviews
        )
        // When
        await viewModel.loadClothes()
        // Then
        XCTAssertEqual(viewModel.averagesByItemID[1]!, 5.0, accuracy: .ulpOfOne)

        reviews.result = .failure(APIError.networkError)
        await viewModel.refreshAverages()

        XCTAssertEqual(viewModel.averagesByItemID[1]!, 5.0, accuracy: .ulpOfOne,
                       "Existing averages should be preserved when a refresh fails")
    }
}
