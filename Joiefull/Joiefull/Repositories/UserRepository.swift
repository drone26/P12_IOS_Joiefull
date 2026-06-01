//
//  UserRepository.swift
//  UserRepository
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation

protocol UserRepositoryProtocol: Sendable {
    func fetchUsers() async throws -> [User]
    func currentUser() async throws -> User
}

actor UserRepository: UserRepositoryProtocol {
    static let shared = UserRepository()

    private let apiService: APIService
    private var cachedUsers: [User]?

    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }

    func fetchUsers() async throws -> [User] {
        if let cachedUsers { return cachedUsers }
        let users: [User] = try await apiService.request(Endpoint.fetchUsers)
        cachedUsers = users
        return users
    }

    func currentUser() async throws -> User {
        let users = try await fetchUsers()
        guard let first = users.first else {
            throw APIError.notFound(reason: "No user available")
        }
        return first
    }

    private enum Endpoint: APIEndpoint {
        case fetchUsers

        var baseURL: URL? { Constants.API.baseURL }

        var path: String {
            switch self {
            case .fetchUsers:
                return "users/"
            }
        }

        var method: HTTPMethod { .get }
        var headers: [String: String]? { nil }
        var body: Data? { nil }
    }
}
