// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
import SmithyHTTPAPI
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class UserAgentProductTokenHTTPClientTests: XCTestCase {
    private final class RecordingHTTPClient: HTTPClient {
        private(set) var lastRequest: HTTPRequest?
        private let responseBody: String?

        init(responseBody: String? = nil) {
            self.responseBody = responseBody
        }

        func send(request: HTTPRequest) async throws -> HTTPResponse {
            lastRequest = request
            guard let responseBody = responseBody else {
                return HTTPResponse(body: .noStream, statusCode: .ok)
            }
            return HTTPResponse(
                headers: Headers(["Content-Type": "application/json"]),
                body: .data(Data(responseBody.utf8)),
                statusCode: .ok
            )
        }
    }

    private let token = Constants.userAgentProductToken()

    private func makeRequest(userAgent: String? = nil) -> HTTPRequest {
        let builder = HTTPRequestBuilder()
            .withMethod(.post)
            .withHost("participant.connect.us-west-2.amazonaws.com")
            .withPath("/participant/connection")
        if let userAgent = userAgent {
            _ = builder.withHeader(name: "User-Agent", value: userAgent)
        }
        return builder.build()
    }

    func testAppendsProductTokenToExistingUserAgent() async throws {
        let recorder = RecordingHTTPClient()
        let client = UserAgentProductTokenHTTPClient(wrapping: recorder, productToken: token)

        _ = try await client.send(request: makeRequest(userAgent: "aws-sdk-swift/1.0 api/connectparticipant"))

        XCTAssertEqual(
            recorder.lastRequest?.headers.value(for: "User-Agent"),
            "aws-sdk-swift/1.0 api/connectparticipant \(token)"
        )
    }

    func testSetsProductTokenWhenUserAgentMissing() async throws {
        let recorder = RecordingHTTPClient()
        let client = UserAgentProductTokenHTTPClient(wrapping: recorder, productToken: token)

        _ = try await client.send(request: makeRequest())

        XCTAssertEqual(recorder.lastRequest?.headers.value(for: "User-Agent"), token)
    }

    func testDoesNotDuplicateTokenOnRetriedRequest() async throws {
        let recorder = RecordingHTTPClient()
        let client = UserAgentProductTokenHTTPClient(wrapping: recorder, productToken: token)
        let request = makeRequest(userAgent: "aws-sdk-swift/1.0")

        _ = try await client.send(request: request)
        _ = try await client.send(request: request)

        XCTAssertEqual(
            recorder.lastRequest?.headers.value(for: "User-Agent"),
            "aws-sdk-swift/1.0 \(token)"
        )
    }

    func testProductTokenMatchesLegacyFormat() {
        XCTAssertEqual(token, "AmazonConnect-Mobile Chat-iOS SDK/\(CommonUtils.getLibraryVersion())")
    }

    func testGeneratedClientSendsUnsignedTokenAuthorizedRequests() async throws {
        let recorder = RecordingHTTPClient(responseBody: #"{"ConnectionCredentials":{"ConnectionToken":"connection-token"},"Websocket":{"Url":"wss://example.com"}}"#)
        var config = try AWSClient.makeClientConfig(region: .usWest2)
        config.httpClientEngine = UserAgentProductTokenHTTPClient(wrapping: recorder, productToken: token)
        let client = ConnectParticipantClient(config: config)

        var input = CreateParticipantConnectionInput()
        input.participantToken = "participant-token"
        input.type = Constants.ACPSRequestTypes
        let output = try await client.createParticipantConnection(input: input)

        let request = try XCTUnwrap(recorder.lastRequest)
        XCTAssertEqual(output.connectionCredentials?.connectionToken, "connection-token")
        XCTAssertEqual(request.headers.value(for: "X-Amz-Bearer"), "participant-token")
        XCTAssertFalse(request.headers.exists(name: "Authorization"), "Requests must not be SigV4 signed")
        XCTAssertFalse(request.headers.exists(name: "X-Amz-Security-Token"))
        XCTAssertTrue(request.headers.value(for: "User-Agent")?.hasSuffix(" \(token)") ?? false)
    }
}
