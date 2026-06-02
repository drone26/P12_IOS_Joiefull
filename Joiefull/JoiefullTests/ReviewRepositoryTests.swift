//
//  ReviewRepositoryTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 02/06/2026.
//

import Testing
import Foundation
@testable import Joiefull

private final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var data: Data
    var response: URLResponse
    var error: Error?
    private(set) var callCount = 0

    init(data: Data = Data(), response: URLResponse, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        callCount += 1
        if let error { throw error }
        return (data, response)
    }
}

private func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://api.example.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

@MainActor
struct ReviewRepositoryTests {

    @Test func fetchReviews_fetchesFromAPI_andCachesResult() async throws {
        let expectedReviews = [
            Review(id: 1, clothingId: 10, userId: 1, text: "Great", rating: 5),
            Review(id: 2, clothingId: 11, userId: 2, text: "Bad", rating: 2)
        ]
        let data = try JSONEncoder().encode(expectedReviews)
        let session = MockURLSession(data: data, response: httpResponse(200))
        let apiService = APIService(session: session)
        let repository = ReviewRepository(apiService: apiService)

        // First fetch should hit the API
        let firstFetch = try await repository.fetchReviews()
        #expect(firstFetch == expectedReviews)
        #expect(session.callCount == 1)

        // Second fetch should return cached data without hitting API
        let secondFetch = try await repository.fetchReviews()
        #expect(secondFetch == expectedReviews)
        #expect(session.callCount == 1)
    }
    
    @Test func upsertReview_addsNewReviewToCache_whenItDoesNotExist() async throws {
        let session = MockURLSession(response: httpResponse(200))
        let apiService = APIService(session: session)
        let repository = ReviewRepository(apiService: apiService)
        
        let newReview = Review(id: 99, clothingId: 42, userId: 7, text: "Awesome", rating: 5)
        
        // Upsert should add it to the cache
        await repository.upsertReview(newReview)
        
        // Fetch should now return the cached array, bypassing the API
        let fetchedReviews = try await repository.fetchReviews()
        #expect(fetchedReviews.count == 1)
        #expect(fetchedReviews.first == newReview)
        #expect(session.callCount == 0) // No API calls were made
    }

    @Test func upsertReview_updatesExistingReviewInCache_whenItAlreadyExists() async throws {
        let session = MockURLSession(response: httpResponse(200))
        let apiService = APIService(session: session)
        let repository = ReviewRepository(apiService: apiService)
        
        let initialReview = Review(id: 1, clothingId: 42, userId: 7, text: "Old text", rating: 3)
        let updatedReview = Review(id: 1, clothingId: 42, userId: 7, text: "New text", rating: 5)
        
        await repository.upsertReview(initialReview)
        await repository.upsertReview(updatedReview)
        
        let fetchedReviews = try await repository.fetchReviews()
        #expect(fetchedReviews.count == 1)
        #expect(fetchedReviews.first == updatedReview)
        #expect(fetchedReviews.first?.text == "New text")
    }
}
