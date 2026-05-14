import Foundation

nonisolated enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case decodingFailed
    case badRequest(reason: String?)
    case notFound(reason: String?)
    case serverError(statusCode: Int, reason: String?)
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .decodingFailed:
            return "Failed to decode server response"
        case .badRequest(let reason):
            return reason ?? "Bad request"
        case .notFound(let reason):
            return reason ?? "Not found"
        case .serverError(let statusCode, let reason):
            return reason ?? "Server error: \(statusCode)"
        case .networkError:
            return "Network error"
        }
    }
}

nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

nonisolated protocol APIEndpoint {
    var baseURL: URL? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

actor APIService {
    private let session: URLSessionProtocol
    private let decoder: JSONDecoder

    init(session: URLSessionProtocol = URLSession.shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let urlRequest = try buildRequest(from: endpoint)
        let (data, response) = try await session.data(for: urlRequest)
        try validateResponse(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let reason = try? decoder.decode(BackendErrorResponse.self, from: data).reason
            switch httpResponse.statusCode {
            case 400:
                throw APIError.badRequest(reason: reason)
            case 404:
                throw APIError.notFound(reason: reason)
            default:
                throw APIError.serverError(statusCode: httpResponse.statusCode, reason: reason)
            }
        }
    }

    private func buildRequest(from endpoint: APIEndpoint) throws -> URLRequest {
        guard let fullURL = endpoint.baseURL?.appending(path: endpoint.path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: fullURL)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        request.httpBody = endpoint.body

        return request
    }
}

nonisolated private struct BackendErrorResponse: Codable {
    let error: Bool
    let reason: String
}
