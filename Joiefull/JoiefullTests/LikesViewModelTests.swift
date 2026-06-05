//
//  LikesViewModelTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 02/06/2026.
//

import XCTest
@testable import Joiefull

// MARK: - Test fake

private final class FakeLikesRepository: LikesRepositoryProtocol, @unchecked Sendable {
    var result: Result<[Like], Error> = .success([])
    private(set) var fetchCount = 0
    private(set) var toggleHistory: [(clothingId: Int, userId: Int)] = []

    func fetchLikes() async throws -> [Like] {
        fetchCount += 1
        return try result.get()
    }
    
    func toggleLike(for clothingId: Int, userId: Int) async {
        toggleHistory.append((clothingId, userId))
        if case .success(var likes) = result {
            if let index = likes.firstIndex(where: { $0.clothingId == clothingId && $0.userId == userId }) {
                likes.remove(at: index)
            } else {
                let newId = (likes.map { $0.id }.max() ?? 0) + 1
                likes.append(Like(id: newId, clothingId: clothingId, userId: userId))
            }
            result = .success(likes)
        }
    }
}

// MARK: - Tests

@MainActor
final class LikesViewModelTests: XCTestCase {

    func test_initialState_isEmpty() {
        // Given
        // When
        let viewModel = LikesViewModel(repository: FakeLikesRepository())
        // Then
        XCTAssertTrue(viewModel.likes.isEmpty)
    }

    func test_loadLikes_populatesLikes_onSuccess() async {
        // Given
        let repo = FakeLikesRepository()
        repo.result = .success([
            Like(id: 1, clothingId: 10, userId: 2),
            Like(id: 2, clothingId: 11, userId: 3)
        ])
        let viewModel = LikesViewModel(repository: repo)
        
        // When
        await viewModel.loadLikes()
        
        // Then
        XCTAssertEqual(viewModel.likes.count, 2)
        XCTAssertEqual(viewModel.likes.first?.clothingId, 10)
    }

    func test_loadLikes_doesNotCrash_onFailure() async {
        // Given
        let repo = FakeLikesRepository()
        repo.result = .failure(APIError.networkError)
        let viewModel = LikesViewModel(repository: repo)
        
        // When
        await viewModel.loadLikes()
        
        // Then
        XCTAssertTrue(viewModel.likes.isEmpty)
    }

    func test_toggleLike_callsRepository_andReloadsLikes() async {
        // Given
        let repo = FakeLikesRepository()
        repo.result = .success([
            Like(id: 1, clothingId: 10, userId: 2)
        ])
        let viewModel = LikesViewModel(repository: repo)
        viewModel.currentUserId = 2
        // When
        await viewModel.loadLikes()
        // Then
        XCTAssertEqual(viewModel.likes.count, 1)
        
        // Toggle should remove it
        await viewModel.toggleLike(for: 10)
        
        XCTAssertEqual(repo.toggleHistory.count, 1)
        XCTAssertEqual(repo.toggleHistory.first?.clothingId, 10)
        XCTAssertEqual(repo.toggleHistory.first?.userId, 2)
        XCTAssertTrue(viewModel.likes.isEmpty)
        
        // Toggle again should add it
        await viewModel.toggleLike(for: 10)
        XCTAssertEqual(viewModel.likes.count, 1)
    }

    func test_isLiked_returnsTrueOnlyForCurrentUsersLikes() async {
        // Given
        let repo = FakeLikesRepository()
        repo.result = .success([
            Like(id: 1, clothingId: 10, userId: 2),
            Like(id: 2, clothingId: 11, userId: 3)
        ])
        let viewModel = LikesViewModel(repository: repo)
        viewModel.currentUserId = 2
        // When
        await viewModel.loadLikes()
        
        // Then
        XCTAssertTrue(viewModel.isLiked(clothingId: 10))
        XCTAssertFalse(viewModel.isLiked(clothingId: 11))
    }

    func test_likesCount_returnsTotalLikesForAnItem() async {
        // Given
        let repo = FakeLikesRepository()
        repo.result = .success([
            Like(id: 1, clothingId: 10, userId: 2),
            Like(id: 2, clothingId: 10, userId: 3),
            Like(id: 3, clothingId: 11, userId: 3)
        ])
        let viewModel = LikesViewModel(repository: repo)
        // When
        await viewModel.loadLikes()
        
        // Then
        XCTAssertEqual(viewModel.likesCount(for: 10), 2)
        XCTAssertEqual(viewModel.likesCount(for: 11), 1)
        XCTAssertEqual(viewModel.likesCount(for: 99), 0)
    }
}
