//
//  LikesRepository.swift
//  LikesRepository
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import Foundation
import Observation

protocol LikesRepositoryProtocol: Sendable {
    func fetchLikes() async throws -> [Like]
    func toggleLike(for clothingId: Int, userId: Int) async
}

actor LikesRepository: LikesRepositoryProtocol {
    static let shared = LikesRepository()
    
    private let apiService: APIService
    private var cachedLikes: [Like]?
    
    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }
    
    func fetchLikes() async throws -> [Like] {
        if let cachedLikes { return cachedLikes }
        let likes: [Like] = try await apiService.request(Endpoint.fetchLikes)
        cachedLikes = likes
        return likes
    }
    
    func toggleLike(for clothingId: Int, userId: Int) {
        var currentLikes = cachedLikes ?? []
        if let index = currentLikes.firstIndex(where: { $0.clothingId == clothingId && $0.userId == userId }) {
            currentLikes.remove(at: index)
        } else {
            let newId = (currentLikes.map { $0.id }.max() ?? 0) + 1
            currentLikes.append(Like(id: newId, clothingId: clothingId, userId: userId))
        }
        cachedLikes = currentLikes
    }
    
    private enum Endpoint: APIEndpoint {
        case fetchLikes
        
        var baseURL: URL? { Constants.API.baseURL }
        
        var path: String {
            switch self {
            case .fetchLikes:
                return "likes/"
            }
        }
        
        var method: HTTPMethod { .get }
        var headers: [String: String]? { nil }
        var body: Data? { nil }
    }
}
