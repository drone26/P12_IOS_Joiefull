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
    static let shared = ClothesRepository()

    private let apiService: APIService
    private var cachedClothes: [ClothingItem]?

    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }

    func fetchClothes() async throws -> [ClothingItem] {
        if let cachedClothes { return cachedClothes }
        let clothes: [ClothingItem] = try await apiService.request(Endpoint.fetchClothes)
        cachedClothes = clothes
        return clothes
    }

    private enum Endpoint: APIEndpoint {
        case fetchClothes

        var baseURL: URL? { Constants.API.baseURL }

        var path: String {
            switch self {
            case .fetchClothes:
                return "clothes/"
            }
        }

        var method: HTTPMethod { .get }
        var headers: [String: String]? { nil }
        var body: Data? { nil }
    }
}
