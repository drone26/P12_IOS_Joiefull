//
//  LikesRepositoryTests.swift
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
struct LikesRepositoryTests {

    @Test func fetchLikes_fetchesFromAPI_andCachesResult() async throws {
        let expectedLikes = [
            Like(id: 1, clothingId: 10, userId: 1),
            Like(id: 2, clothingId: 11, userId: 2)
        ]
        let data = try JSONEncoder().encode(expectedLikes)
        let session = MockURLSession(data: data, response: httpResponse(200))
        let apiService = APIService(session: session)
        let repository = LikesRepository(apiService: apiService)

        // First fetch should hit the API
        let firstFetch = try await repository.fetchLikes()
        #expect(firstFetch == expectedLikes)
        #expect(session.callCount == 1)

        // Second fetch should return cached data without hitting API
        let secondFetch = try await repository.fetchLikes()
        #expect(secondFetch == expectedLikes)
        #expect(session.callCount == 1)
    }
    
    @Test func toggleLike_addsNewLikeToCache_whenItDoesNotExist() async throws {
        let session = MockURLSession(response: httpResponse(200))
        let apiService = APIService(session: session)
        let repository = LikesRepository(apiService: apiService)
        
        await repository.toggleLike(for: 42, userId: 7)
        
        let fetchedLikes = try await repository.fetchLikes()
        #expect(fetchedLikes.count == 1)
        #expect(fetchedLikes.first?.clothingId == 42)
        #expect(fetchedLikes.first?.userId == 7)
        #expect(session.callCount == 0) // No API calls were made
    }

    @Test func toggleLike_removesExistingLikeFromCache_whenItAlreadyExists() async throws {
        let session = MockURLSession(response: httpResponse(200))
        let apiService = APIService(session: session)
        let repository = LikesRepository(apiService: apiService)
        
        // Setup initial like
        await repository.toggleLike(for: 42, userId: 7)
        var fetchedLikes = try await repository.fetchLikes()
        #expect(fetchedLikes.count == 1)
        
        // Toggle again should remove it
        await repository.toggleLike(for: 42, userId: 7)
        fetchedLikes = try await repository.fetchLikes()
        #expect(fetchedLikes.isEmpty)
    }
}
