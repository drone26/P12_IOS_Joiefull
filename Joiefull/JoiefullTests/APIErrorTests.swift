//
//  APIErrorTests.swift
//  JoiefullTests
//
//  Created by Mathieu ARRIO on 27/05/2026.
//

import Foundation
import Testing
@testable import Joiefull

struct APIErrorTests {

    @Test func errorDescription_invalidURL() {
        #expect(APIError.invalidURL.errorDescription == "Invalid URL")
    }

    @Test func errorDescription_decodingFailed() {
        #expect(APIError.decodingFailed.errorDescription == "Failed to decode server response")
    }

    @Test func errorDescription_networkError() {
        #expect(APIError.networkError.errorDescription == "Network error")
    }

    @Test func errorDescription_badRequest_usesReasonWhenAvailable() {
        #expect(APIError.badRequest(reason: "Missing field").errorDescription == "Missing field")
    }

    @Test func errorDescription_badRequest_fallsBackWhenReasonIsNil() {
        #expect(APIError.badRequest(reason: nil).errorDescription == "Bad request")
    }

    @Test func errorDescription_notFound_usesReasonWhenAvailable() {
        #expect(APIError.notFound(reason: "User absent").errorDescription == "User absent")
    }

    @Test func errorDescription_notFound_fallsBackWhenReasonIsNil() {
        #expect(APIError.notFound(reason: nil).errorDescription == "Not found")
    }

    @Test func errorDescription_serverError_usesReasonWhenAvailable() {
        #expect(APIError.serverError(statusCode: 500, reason: "Boom").errorDescription == "Boom")
    }

    @Test func errorDescription_serverError_fallsBackWithStatusCode() {
        #expect(APIError.serverError(statusCode: 503, reason: nil).errorDescription == "Server error: 503")
    }

    @Test func equatable_distinguishesCases() {
        #expect(APIError.invalidURL == APIError.invalidURL)
        #expect(APIError.invalidURL != APIError.networkError)
        #expect(APIError.badRequest(reason: "a") == APIError.badRequest(reason: "a"))
        #expect(APIError.badRequest(reason: "a") != APIError.badRequest(reason: "b"))
        #expect(APIError.notFound(reason: nil) != APIError.notFound(reason: "x"))
        #expect(APIError.serverError(statusCode: 500, reason: nil) != APIError.serverError(statusCode: 501, reason: nil))
    }
}

struct HTTPMethodTests {

    @Test func rawValues_matchHTTPSpec() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
    }
}
