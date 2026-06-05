//
//  ClothingDetailViewModelTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 01/06/2026.
//

import XCTest
@testable import Joiefull

// MARK: - Test fakes

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

private final class FakeUserRepository: UserRepositoryProtocol, @unchecked Sendable {
    var usersResult: Result<[User], Error> = .success([])
    var currentUserResult: Result<User, Error> = .failure(APIError.notFound(reason: "no user"))

    func fetchUsers() async throws -> [User] {
        try usersResult.get()
    }

    func currentUser() async throws -> User {
        try currentUserResult.get()
    }
}

// MARK: - Fixture builders

private func makeItem(id: Int) -> ClothingItem {
    ClothingItem(
        id: id,
        picture: Picture(url: URL(string: "https://example.com/\(id).jpg")!, description: "d"),
        name: "Item",
        category: .tops,
        price: 10,
        originalPrice: 10
    )
}

private func makeUser(
    id: Int = 1,
    firstName: String = "Jane",
    lastName: String = "Doe"
) -> User {
    User(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: "\(firstName.lowercased())@example.com",
        avatarURL: nil
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
final class ClothingDetailViewModelTests: XCTestCase {

    // MARK: - itemReviews

    func test_itemReviews_filtersByClothingID() async {
        // Given
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 42, userId: 1),
            makeReview(id: 2, clothingId: 99, userId: 2),
            makeReview(id: 3, clothingId: 42, userId: 3)
        ])
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 42),
            reviewRepository: reviews,
            userRepository: FakeUserRepository()
        )

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.itemReviews.map(\.id).sorted(), [1, 3])
    }

    // MARK: - averageRating

    func test_averageRating_returnsItemFallback_whenNoReviewsAndNoUserRating() {
        // Given
        let item = makeItem(id: 0)
        let viewModel = ClothingDetailViewModel(
            item: item,
            reviewRepository: FakeReviewRepository(),
            userRepository: FakeUserRepository()
        )
        // When

        // Then
        XCTAssertEqual(viewModel.averageRating, item.rating, accuracy: .ulpOfOne)
    }

    func test_averageRating_averagesAllReviews_whenNoUserRating() async {
        // Given
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 1, userId: 2, rating: 4),
            makeReview(id: 2, clothingId: 1, userId: 3, rating: 2)
        ])
        let users = FakeUserRepository()
        users.usersResult = .success([makeUser(id: 1)])
        users.currentUserResult = .success(makeUser(id: 1))
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: users
        )

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.averageRating, 3.0, accuracy: .ulpOfOne)
    }

    func test_averageRating_substitutesUserRating_forCurrentUsersExistingReview() async {
        // Given
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 1, userId: 1, rating: 5),  // current user
            makeReview(id: 2, clothingId: 1, userId: 2, rating: 3)
        ])
        let users = FakeUserRepository()
        users.usersResult = .success([makeUser(id: 1), makeUser(id: 2)])
        users.currentUserResult = .success(makeUser(id: 1))
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: users
        )
        // When
        await viewModel.load()

        viewModel.userRating = 1

        // Current user's existing review (5) is dropped, replaced by userRating (1).
        // Average becomes (3 + 1) / 2 = 2.0.
        // Then
        XCTAssertEqual(viewModel.averageRating, 2.0, accuracy: .ulpOfOne)
    }

    func test_averageRating_includesUserRating_whenCurrentUserHasNoExistingReview() async {
        // Given
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 1, userId: 2, rating: 4),
            makeReview(id: 2, clothingId: 1, userId: 3, rating: 4)
        ])
        let users = FakeUserRepository()
        users.usersResult = .success([makeUser(id: 1)])
        users.currentUserResult = .success(makeUser(id: 1))
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: users
        )
        // When
        await viewModel.load()

        viewModel.userRating = 1

        // Both reviews kept (neither belongs to current user), plus userRating.
        // Average = (4 + 4 + 1) / 3 = 3.0.
        // Then
        XCTAssertEqual(viewModel.averageRating, 3.0, accuracy: .ulpOfOne)
    }

    // MARK: - user(for:)

    func test_user_returnsUserFromMap_afterLoad() async {
        // Given
        let alice = makeUser(id: 7, firstName: "Alice")
        let users = FakeUserRepository()
        users.usersResult = .success([alice])
        users.currentUserResult = .success(alice)
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: FakeReviewRepository(),
            userRepository: users
        )

        // When
        await viewModel.load()

        let review = makeReview(id: 1, clothingId: 1, userId: 7)
        // Then
        XCTAssertEqual(viewModel.user(for: review)?.id, 7)
    }

    func test_user_returnsNil_whenUserMissingFromMap() async {
        // Given
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: FakeReviewRepository(),
            userRepository: FakeUserRepository()
        )

        // When
        await viewModel.load()

        let review = makeReview(id: 1, clothingId: 1, userId: 999)
        // Then
        XCTAssertNil(viewModel.user(for: review))
    }

    // MARK: - load()

    func test_load_populatesReviewsUsersAndCurrentUser() async {
        // Given
        let alice = makeUser(id: 1, firstName: "Alice")
        let bob = makeUser(id: 2, firstName: "Bob")
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 1, userId: 2, rating: 4)
        ])
        let users = FakeUserRepository()
        users.usersResult = .success([alice, bob])
        users.currentUserResult = .success(alice)
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: users
        )

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.reviews.count, 1)
        XCTAssertEqual(viewModel.usersByID[1]?.firstName, "Alice")
        XCTAssertEqual(viewModel.usersByID[2]?.firstName, "Bob")
        XCTAssertEqual(viewModel.currentUser?.id, 1)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_load_setsErrorMessage_whenReviewsFetchFails() async {
        // Given
        let reviews = FakeReviewRepository()
        reviews.result = .failure(APIError.networkError)
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: FakeUserRepository()
        )

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.errorMessage, APIError.networkError.errorDescription)
        XCTAssertTrue(viewModel.reviews.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_load_prefillsRatingAndText_fromCurrentUsersExistingReview() async {
        // Given
        let alice = makeUser(id: 5, firstName: "Alice")
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 42, userId: 5, text: "Adorable", rating: 4)
        ])
        let users = FakeUserRepository()
        users.usersResult = .success([alice])
        users.currentUserResult = .success(alice)
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 42),
            reviewRepository: reviews,
            userRepository: users
        )

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.userRating, 4)
        XCTAssertEqual(viewModel.reviewText, "Adorable")
    }

    func test_load_leavesRatingAndTextEmpty_whenNoExistingReviewFromCurrentUser() async {
        // Given
        let alice = makeUser(id: 5)
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 1, clothingId: 42, userId: 9, rating: 4)
        ])
        let users = FakeUserRepository()
        users.usersResult = .success([alice])
        users.currentUserResult = .success(alice)
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 42),
            reviewRepository: reviews,
            userRepository: users
        )

        // When
        await viewModel.load()

        // Then
        XCTAssertEqual(viewModel.userRating, 0)
        XCTAssertEqual(viewModel.reviewText, "")
    }

    // MARK: - submitReview()

    func test_submitReview_doesNothing_whenCurrentUserIsMissing() async {
        // Given
        let reviews = FakeReviewRepository()
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: FakeUserRepository() // currentUser fails
        )
        // When
        await viewModel.load()

        viewModel.userRating = 4
        viewModel.reviewText = "Looks great"

        await viewModel.submitReview()

        // Then
        XCTAssertTrue(reviews.upsertedReviews.isEmpty,
                      "submitReview must short-circuit when no current user is loaded")
    }

    func test_submitReview_doesNothing_whenNoRatingAndNoText() async {
        // Given
        let alice = makeUser(id: 1)
        let users = FakeUserRepository()
        users.usersResult = .success([alice])
        users.currentUserResult = .success(alice)
        let reviews = FakeReviewRepository()
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: users
        )
        // When
        await viewModel.load()

        await viewModel.submitReview()

        // Then
        XCTAssertTrue(reviews.upsertedReviews.isEmpty,
                      "submitReview must skip when the user did not rate or type anything")
    }

    func test_submitReview_createsNewReview_withIncrementedID() async {
        // Given
        let alice = makeUser(id: 1)
        let users = FakeUserRepository()
        users.usersResult = .success([alice])
        users.currentUserResult = .success(alice)
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 3, clothingId: 99, userId: 2, rating: 4),
            makeReview(id: 7, clothingId: 99, userId: 3, rating: 5)
        ])
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 99),
            reviewRepository: reviews,
            userRepository: users
        )
        // When
        await viewModel.load()

        viewModel.userRating = 5
        viewModel.reviewText = "Top"

        await viewModel.submitReview()

        let upserted = try? XCTUnwrap(reviews.upsertedReviews.last)
        // Then
        XCTAssertEqual(upserted?.id, 8, "New review id should be max(existingIDs) + 1")
        XCTAssertEqual(upserted?.userId, 1)
        XCTAssertEqual(upserted?.clothingId, 99)
        XCTAssertEqual(upserted?.rating, 5)
        XCTAssertEqual(upserted?.text, "Top")
    }

    func test_submitReview_updatesExistingReview_keepingItsID() async {
        // Given
        let alice = makeUser(id: 5)
        let users = FakeUserRepository()
        users.usersResult = .success([alice])
        users.currentUserResult = .success(alice)
        let reviews = FakeReviewRepository()
        reviews.result = .success([
            makeReview(id: 12, clothingId: 1, userId: 5, text: "Old", rating: 2)
        ])
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: users
        )
        // When
        await viewModel.load()
        // Then
        XCTAssertEqual(viewModel.userRating, 2, "Sanity check: existing rating prefilled")

        viewModel.userRating = 4
        viewModel.reviewText = "Better"

        await viewModel.submitReview()

        let upserted = try? XCTUnwrap(reviews.upsertedReviews.last)
        XCTAssertEqual(upserted?.id, 12, "Updating an existing review must keep its original id")
        XCTAssertEqual(upserted?.rating, 4)
        XCTAssertEqual(upserted?.text, "Better")
    }

    func test_submitReview_refreshesReviewsAfterUpsert() async {
        // Given
        let alice = makeUser(id: 1)
        let users = FakeUserRepository()
        users.usersResult = .success([alice])
        users.currentUserResult = .success(alice)
        let reviews = FakeReviewRepository()
        reviews.result = .success([])
        let viewModel = ClothingDetailViewModel(
            item: makeItem(id: 1),
            reviewRepository: reviews,
            userRepository: users
        )
        // When
        await viewModel.load()
        let baselineFetchCount = reviews.fetchCount

        viewModel.userRating = 3
        viewModel.reviewText = "Bien"

        await viewModel.submitReview()

        // Then
        XCTAssertGreaterThan(reviews.fetchCount, baselineFetchCount,
                             "submitReview should re-fetch reviews after upserting")
        XCTAssertEqual(viewModel.reviews.count, 1)
        XCTAssertEqual(viewModel.reviews.first?.userId, 1)
    }
}
