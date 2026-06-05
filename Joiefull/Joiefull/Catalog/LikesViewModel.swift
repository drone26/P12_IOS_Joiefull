//
//  LikesViewModel.swift
//  LikesViewModel
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import Foundation
import Observation

@Observable
final class LikesViewModel {
    private let repository: LikesRepositoryProtocol
    private(set) var likes: [Like] = []
    
    var currentUserId: Int = 2
    
    init(repository: LikesRepositoryProtocol = LikesRepository.shared) {
        self.repository = repository
    }
    
    func loadLikes() async {
        do {
            let fetchedLikes = try await repository.fetchLikes()
            await MainActor.run {
                self.likes = fetchedLikes
            }
        } catch {
            print("Error fetching likes: \(error)")
        }
    }
    
    func toggleLike(for clothingId: Int) async {
        await repository.toggleLike(for: clothingId, userId: currentUserId)
        if let updatedLikes = try? await repository.fetchLikes() {
            await MainActor.run {
                self.likes = updatedLikes
            }
        }
    }
    
    func isLiked(clothingId: Int) -> Bool {
        likes.contains(where: { $0.clothingId == clothingId && $0.userId == currentUserId })
    }
    
    func likesCount(for clothingId: Int) -> Int {
        likes.filter { $0.clothingId == clothingId }.count
    }
}
