//
//  APIServiceTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation
import Testing
@testable import Joiefull

// MARK: - Test fixtures

private struct TestEndpoint: APIEndpoint {
    var baseURL: URL? = URL(string: "https://api.example.com")
    var path: String = "items"
    var method: HTTPMethod = .get
    var headers: [String: String]? = nil
    var body: Data? = nil
}

private struct NoBaseURLEndpoint: APIEndpoint {
    var baseURL: URL? = nil
    var path: String = "x"
    var method: HTTPMethod = .get
    var headers: [String: String]? = nil
    var body: Data? = nil
}

private struct Payload: Codable, Equatable {
    let name: String
}

private final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var data: Data
    var response: URLResponse
    var error: Error?
    private(set) var lastRequest: URLRequest?

    init(data: Data = Data(), response: URLResponse, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error { throw error }
        return (data, response)
    }
}

private func httpResponse(_ statusCode: Int, url: URL = URL(string: "https://api.example.com")!) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

// MARK: - Tests

struct APIServiceTests {

    @Test func request_decodesSuccessfulResponse() async throws {
        let payload = Payload(name: "joie")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(data: data, response: httpResponse(200))
        let service = APIService(session: session)

        let result: Payload = try await service.request(TestEndpoint())
        #expect(result == payload)
    }

    @Test func request_buildsURLByAppendingPathToBaseURL() async throws {
        let payload = Payload(name: "joie")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(data: data, response: httpResponse(200))
        let service = APIService(session: session)

        _ = try await service.request(TestEndpoint()) as Payload

        let request = try #require(session.lastRequest)
        #expect(request.url?.absoluteString == "https://api.example.com/items")
    }

    @Test func request_setsHTTPMethodFromEndpoint() async throws {
        let payload = Payload(name: "x")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(data: data, response: httpResponse(200))
        let service = APIService(session: session)

        var endpoint = TestEndpoint()
        endpoint.method = .post
        _ = try await service.request(endpoint) as Payload

        #expect(session.lastRequest?.httpMethod == "POST")
    }

    @Test func request_setsContentTypeHeader_whenNotProvided() async throws {
        let payload = Payload(name: "x")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(data: data, response: httpResponse(200))
        let service = APIService(session: session)

        _ = try await service.request(TestEndpoint()) as Payload

        #expect(session.lastRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func request_preservesCustomContentTypeFromEndpoint() async throws {
        let payload = Payload(name: "x")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(data: data, response: httpResponse(200))
        let service = APIService(session: session)

        var endpoint = TestEndpoint()
        endpoint.headers = ["Content-Type": "text/plain", "Authorization": "Bearer token"]
        _ = try await service.request(endpoint) as Payload

        #expect(session.lastRequest?.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        #expect(session.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    }

    @Test func request_attachesBodyFromEndpoint() async throws {
        let payload = Payload(name: "x")
        let data = try JSONEncoder().encode(payload)
        let session = MockURLSession(data: data, response: httpResponse(200))
        let service = APIService(session: session)

        var endpoint = TestEndpoint()
        endpoint.body = "hello".data(using: .utf8)
        _ = try await service.request(endpoint) as Payload

        #expect(session.lastRequest?.httpBody == "hello".data(using: .utf8))
    }

    @Test func request_throwsInvalidURL_whenEndpointBaseURLIsNil() async {
        let session = MockURLSession(response: httpResponse(200))
        let service = APIService(session: session)

        await #expect(throws: APIError.invalidURL) {
            _ = try await service.request(NoBaseURLEndpoint()) as Payload
        }
    }

    @Test func request_throwsNetworkError_whenResponseIsNotHTTP() async {
        let nonHTTPResponse = URLResponse(
            url: URL(string: "https://x")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        let session = MockURLSession(response: nonHTTPResponse)
        let service = APIService(session: session)

        await #expect(throws: APIError.networkError) {
            _ = try await service.request(TestEndpoint()) as Payload
        }
    }

    @Test func request_throwsBadRequest_on400() async throws {
        let backendError = #"{"error": true, "reason": "Invalid"}"#.data(using: .utf8)!
        let session = MockURLSession(data: backendError, response: httpResponse(400))
        let service = APIService(session: session)

        await #expect(throws: APIError.badRequest(reason: "Invalid")) {
            _ = try await service.request(TestEndpoint()) as Payload
        }
    }

    @Test func request_throwsBadRequest_withNilReason_when400BodyIsUnparseable() async {
        let session = MockURLSession(data: Data(), response: httpResponse(400))
        let service = APIService(session: session)

        await #expect(throws: APIError.badRequest(reason: nil)) {
            _ = try await service.request(TestEndpoint()) as Payload
        }
    }

    @Test func request_throwsNotFound_on404() async {
        let backendError = #"{"error": true, "reason": "Missing"}"#.data(using: .utf8)!
        let session = MockURLSession(data: backendError, response: httpResponse(404))
        let service = APIService(session: session)

        await #expect(throws: APIError.notFound(reason: "Missing")) {
            _ = try await service.request(TestEndpoint()) as Payload
        }
    }

    @Test func request_throwsServerError_on500() async {
        let backendError = #"{"error": true, "reason": "Boom"}"#.data(using: .utf8)!
        let session = MockURLSession(data: backendError, response: httpResponse(500))
        let service = APIService(session: session)

        await #expect(throws: APIError.serverError(statusCode: 500, reason: "Boom")) {
            _ = try await service.request(TestEndpoint()) as Payload
        }
    }

    @Test func request_throwsServerError_onUnknownStatus() async {
        let session = MockURLSession(data: Data(), response: httpResponse(418))
        let service = APIService(session: session)

        await #expect(throws: APIError.serverError(statusCode: 418, reason: nil)) {
            _ = try await service.request(TestEndpoint()) as Payload
        }
    }

    @Test func request_throwsDecodingFailed_whenPayloadIsInvalid() async {
        let invalid = "not a json".data(using: .utf8)!
        let session = MockURLSession(data: invalid, response: httpResponse(200))
        let service = APIService(session: session)

        await #expect(throws: APIError.decodingFailed) {
            _ = try await service.request(TestEndpoint()) as Payload
        }
    }
}
