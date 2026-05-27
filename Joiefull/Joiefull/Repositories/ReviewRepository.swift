//
//  ReviewRepository.swift
//  ReviewRepository
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation

protocol ReviewRepositoryProtocol: Sendable {
    func fetchReviews() async throws -> [Review]
    func upsertReview(_ review: Review) async
}

actor ReviewRepository: ReviewRepositoryProtocol {
    static let shared = ReviewRepository()

    private let apiService: APIService
    private var cachedReviews: [Review]?

    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }

    func fetchReviews() async throws -> [Review] {
        if let cachedReviews { return cachedReviews }
        let reviews: [Review] = try await apiService.request(Endpoint.fetchReviews)
        cachedReviews = reviews
        return reviews
    }

    func upsertReview(_ review: Review) {
        var reviews = cachedReviews ?? []
        if let index = reviews.firstIndex(where: { $0.clothingId == review.clothingId && $0.userId == review.userId }) {
            reviews[index] = review
        } else {
            reviews.append(review)
        }
        cachedReviews = reviews
    }

    private enum Endpoint: APIEndpoint {
        case fetchReviews

        var baseURL: URL? { Constants.API.baseURL }

        var path: String {
            switch self {
            case .fetchReviews:
                return "reviews/"
            }
        }

        var method: HTTPMethod { .get }
        var headers: [String: String]? { nil }
        var body: Data? { nil }
    }
}
