//
//  ClothingDetailViewModel.swift
//  ClothingDetailViewModel
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation

@Observable
final class ClothingDetailViewModel {
    let item: ClothingItem
    private(set) var reviews: [Review] = []
    private(set) var usersByID: [Int: User] = [:]
    private(set) var currentUser: User?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var userRating: Int = 0
    var reviewText: String = ""

    private let reviewRepository: ReviewRepositoryProtocol
    private let userRepository: UserRepositoryProtocol

    init(
        item: ClothingItem,
        reviewRepository: ReviewRepositoryProtocol = ReviewRepository.shared,
        userRepository: UserRepositoryProtocol = UserRepository.shared
    ) {
        self.item = item
        self.reviewRepository = reviewRepository
        self.userRepository = userRepository
    }

    var itemReviews: [Review] {
        reviews.filter { $0.clothingId == item.id }
    }

    var averageRating: Double {
        let currentUserID = currentUser?.id
        var ratings: [Double] = []
        for review in itemReviews {
            if userRating > 0, review.userId == currentUserID {
                continue
            }
            ratings.append(Double(review.rating))
        }
        if userRating > 0 {
            ratings.append(Double(userRating))
        }
        guard !ratings.isEmpty else { return item.rating }
        return ratings.reduce(0, +) / Double(ratings.count)
    }

    func user(for review: Review) -> User? {
        usersByID[review.userId]
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        async let reviewsTask = reviewRepository.fetchReviews()
        async let usersTask = userRepository.fetchUsers()
        async let currentUserTask = userRepository.currentUser()
        do {
            reviews = try await reviewsTask
        } catch {
            errorMessage = error.localizedDescription
        }
        if let fetchedUsers = try? await usersTask {
            usersByID = Dictionary(uniqueKeysWithValues: fetchedUsers.map { ($0.id, $0) })
        }
        currentUser = try? await currentUserTask

        if let existing = currentUserReview() {
            userRating = existing.rating
            reviewText = existing.text
        }

        isLoading = false
    }

    func submitReview() async {
        guard let user = currentUser else { return }
        guard userRating > 0 || !reviewText.isEmpty else { return }
        let existing = currentUserReview()
        let id = existing?.id ?? (reviews.map(\.id).max() ?? 0) + 1
        let review = Review(
            id: id,
            clothingId: item.id,
            userId: user.id,
            text: reviewText,
            rating: userRating
        )
        await reviewRepository.upsertReview(review)
        if let updated = try? await reviewRepository.fetchReviews() {
            reviews = updated
        }
    }

    private func currentUserReview() -> Review? {
        guard let userID = currentUser?.id else { return nil }
        return itemReviews.first { $0.userId == userID }
    }
}
