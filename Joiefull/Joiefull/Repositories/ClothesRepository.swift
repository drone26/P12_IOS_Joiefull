//
//  ClothesRepository.swift
//  ClothesRepository
//
//  Created by Mathieu ARRIO on 12/05/2026.
//
import Foundation

protocol ClothesRepositoryProtocol: Sendable {
    func fetchClothes() async throws -> [ClothingItem]
}

actor ClothesRepository: ClothesRepositoryProtocol {
    private let apiService: APIService

    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }

    func fetchClothes() async throws -> [ClothingItem] {
        try await apiService.request(Endpoint.fetchClothes)
    }

    private enum Endpoint: APIEndpoint {
        case fetchClothes

        var baseURL: URL? { Constants.API.baseURL }

        var path: String {
            switch self {
            case .fetchClothes:
                return "api/clothes.json"
            }
        }

        var method: HTTPMethod { .get }
        var headers: [String: String]? { nil }
        var body: Data? { nil }
    }
}
