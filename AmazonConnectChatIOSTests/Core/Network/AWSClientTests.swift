// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class AWSClientTests: XCTestCase {

    var mockClient: MockAWSConnectParticipant!
    let awsClient = AWSClient.shared

    let dummyToken = "dummyToken"
    let timeout = 1.0

    override func setUp() {
        super.setUp()
        mockClient = MockAWSConnectParticipant()
        let config = GlobalConfig(region: .usEast1)
        AWSClient.shared.configure(with: config, participantClient: mockClient)
    }

    override func tearDown() {
        mockClient = nil
        super.tearDown()
    }

    // Test Configure Method
    func testConfigure() {
        // Given
        let config = GlobalConfig(region: .usEast1)

        // When
        awsClient.configure(with: config, participantClient: mockClient)

        // Then
        XCTAssertEqual(awsClient.region, .usEast1)
        XCTAssertTrue(awsClient.connectParticipantClient is MockAWSConnectParticipant)
    }

    func testConfigure_MapsRegionToRawValue() {
        awsClient.configure(with: GlobalConfig(region: .euWest2), participantClient: mockClient)
        XCTAssertEqual(awsClient.region.rawValue, "eu-west-2")
    }

    func testConfigure_CreatesGeneratedParticipantClient() {
        let client = AWSClient()

        client.configure(with: GlobalConfig(region: .usWest2))

        XCTAssertEqual(client.region, .usWest2)
        XCTAssertTrue(client.connectParticipantClient is AWSConnectParticipantAdapter)
    }

    func testGeneratedClientConfigurationPreservesAuthAndAttribution() throws {
        let config = try AWSClient.makeClientConfig(region: .euWest2)

        XCTAssertEqual(config.region, "eu-west-2")
        XCTAssertEqual(config.appID, Constants.userAgentAppID())
        XCTAssertTrue(config.httpClientEngine is UserAgentProductTokenHTTPClient)
        XCTAssertTrue(config.authSchemeResolver is NoAuthSchemeResolver)
        XCTAssertEqual(AWSClient.placeholderCredentials.accessKey, "")
        XCTAssertEqual(AWSClient.placeholderCredentials.secret, "")
    }

    func testRegionAcceptsArbitraryStringLiteral() {
        let config = GlobalConfig(region: "ap-southeast-4")
        XCTAssertEqual(config.region.rawValue, "ap-southeast-4")
    }

    func testRegionInitializersAndDescription() {
        let rawRegion = Region(rawValue: "eu-central-2")
        let directRegion = Region("eu-central-2")

        XCTAssertEqual(rawRegion, directRegion)
        XCTAssertEqual(rawRegion.description, "eu-central-2")
        XCTAssertEqual(Region.euCentral2.rawValue, "eu-central-2")
        XCTAssertEqual(Region.apSoutheast7.rawValue, "ap-southeast-7")
    }

    func testAWSClientErrorsHaveActionableDescriptions() {
        XCTAssertEqual(
            AWSClient.AWSClientError.invalidConnectionResponse.localizedDescription,
            "ConnectParticipant returned a response without a WebSocket URL or connection token."
        )
        XCTAssertEqual(
            AWSClient.AWSClientError.failedToInitializeParticipantClient.localizedDescription,
            "The ConnectParticipant client has not been configured."
        )
    }

    // MARK: - Create participant connection

    func performCreateParticipantConnectionTest(expectedResult: Result<CreateParticipantConnectionOutput, Error>) {
        mockClient.createParticipantConnectionResult = expectedResult

        let expectation = self.expectation(description: "CreateParticipantConnection")

        awsClient.createParticipantConnection(participantToken: dummyToken) { result in
            switch (expectedResult, result) {
            case (.success(let expectedResponse), .success(let details)):
                XCTAssertEqual(details.websocketUrl, expectedResponse.websocket?.url)
                XCTAssertEqual(details.connectionToken, expectedResponse.connectionCredentials?.connectionToken)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as NSError, expectedError as NSError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCreateParticipantConnection_Success() {
        let response = CreateParticipantConnectionOutput(
            connectionCredentials: ConnectParticipantClientTypes.ConnectionCredentials(connectionToken: dummyToken),
            websocket: ConnectParticipantClientTypes.Websocket(url: "wss://example.com")
        )
        performCreateParticipantConnectionTest(expectedResult: .success(response))
    }

    func testCreateParticipantConnection_Failure() {
        performCreateParticipantConnectionTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }

    // A response without a websocket URL or connection token must fail, not half-populate
    func testCreateParticipantConnection_MissingWebsocketFails() {
        mockClient.createParticipantConnectionResult = .success(CreateParticipantConnectionOutput())
        let expectation = self.expectation(description: "CreateParticipantConnection missing websocket")

        awsClient.createParticipantConnection(participantToken: dummyToken) { result in
            guard case .failure(let error) = result else {
                return XCTFail("Expected failure when websocket/credentials are absent")
            }
            XCTAssertEqual(error as? AWSClient.AWSClientError, .invalidConnectionResponse)
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCreateParticipantConnection_SendsExpectedRequest() {
        mockClient.createParticipantConnectionResult = .success(
            CreateParticipantConnectionOutput(
                connectionCredentials: ConnectParticipantClientTypes.ConnectionCredentials(connectionToken: dummyToken),
                websocket: ConnectParticipantClientTypes.Websocket(url: "wss://example.com")
            )
        )
        let expectation = self.expectation(description: "CreateParticipantConnection request")

        awsClient.createParticipantConnection(participantToken: dummyToken) { _ in expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        let input = mockClient.lastCreateParticipantConnectionInput
        XCTAssertEqual(input?.participantToken, dummyToken)
        XCTAssertEqual(input?.type, [.websocket, .connectionCredentials])
    }

    // MARK: - Disconnect participant

    func performDisconnectParticipantConnectionTest(expectedResult: Result<DisconnectParticipantOutput, Error>) {
        mockClient.disconnectParticipantResult = expectedResult

        let expectation = self.expectation(description: "DisconnectParticipantConnection")

        awsClient.disconnectParticipantConnection(connectionToken: dummyToken) { result in
            switch (expectedResult, result) {
            case (.success, .success(let success)):
                XCTAssertNotNil(success)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as NSError, expectedError as NSError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDisconnectParticipantConnection_Success() {
        performDisconnectParticipantConnectionTest(expectedResult: .success(DisconnectParticipantOutput()))
    }

    func testDisconnectParticipantConnection_Failure() {
        performDisconnectParticipantConnectionTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }

    func testDisconnectParticipantConnection_SendsConnectionToken() {
        mockClient.disconnectParticipantResult = .success(DisconnectParticipantOutput())
        let expectation = self.expectation(description: "Disconnect request")

        awsClient.disconnectParticipantConnection(connectionToken: dummyToken) { _ in expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        XCTAssertEqual(mockClient.lastDisconnectParticipantInput?.connectionToken, dummyToken)
    }

    // MARK: - Send message

    func performSendMessageTest(expectedResult: Result<SendMessageOutput, Error>) {
        mockClient.sendMessageResult = expectedResult

        let expectation = self.expectation(description: "SendMessage")

        awsClient.sendMessage(connectionToken: dummyToken, contentType: .plainText, message: "Hello, world!") { result in
            switch (expectedResult, result) {
            case (.success, .success(let success)):
                XCTAssertNotNil(success)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as NSError, expectedError as NSError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSendMessage_Success() {
        performSendMessageTest(expectedResult: .success(SendMessageOutput()))
    }

    func testSendMessage_Failure() {
        performSendMessageTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }

    func testSendMessage_SendsExpectedRequest() {
        mockClient.sendMessageResult = .success(SendMessageOutput())
        let expectation = self.expectation(description: "SendMessage request")

        awsClient.sendMessage(connectionToken: dummyToken, contentType: .plainText, message: "Hello, world!") { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        let input = mockClient.lastSendMessageInput
        XCTAssertEqual(input?.connectionToken, dummyToken)
        XCTAssertEqual(input?.content, "Hello, world!")
        XCTAssertEqual(input?.contentType, ContentType.plainText.rawValue)
    }

    // MARK: - Send event

    func performSendEventTest(expectedResult: Result<SendEventOutput, Error>) {
        mockClient.sendEventResult = expectedResult

        let expectation = self.expectation(description: "SendEvent")

        awsClient.sendEvent(connectionToken: dummyToken, contentType: .typing, content: "{}") { result in
            switch (expectedResult, result) {
            case (.success, .success(let success)):
                XCTAssertNotNil(success)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as NSError, expectedError as NSError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSendEvent_Success() {
        performSendEventTest(expectedResult: .success(SendEventOutput()))
    }

    func testSendEvent_Failure() {
        performSendEventTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }

    func testSendEvent_SendsExpectedRequest() {
        mockClient.sendEventResult = .success(SendEventOutput())
        let expectation = self.expectation(description: "SendEvent request")

        awsClient.sendEvent(connectionToken: dummyToken, contentType: .typing, content: "{}") { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        let input = mockClient.lastSendEventInput
        XCTAssertEqual(input?.connectionToken, dummyToken)
        XCTAssertEqual(input?.content, "{}")
        XCTAssertEqual(input?.contentType, ContentType.typing.rawValue)
    }

    func testSendEvent_OmitsEmptyContent() {
        mockClient.sendEventResult = .success(SendEventOutput())
        let expectation = self.expectation(description: "SendEvent without content")

        awsClient.sendEvent(connectionToken: dummyToken, contentType: .typing) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        XCTAssertNil(mockClient.lastSendEventInput?.content)
    }

    // MARK: - Get transcript

    func performGetTranscriptTest(expectedResult: Result<GetTranscriptOutput, Error>) {
        mockClient.getTranscriptResult = expectedResult

        let expectation = self.expectation(description: "GetTranscript")

        awsClient.getTranscript(getTranscriptArgs: GetTranscriptInput()) { result in
            switch (expectedResult, result) {
            case (.success(let expectedResponse), .success(let response)):
                XCTAssertEqual(expectedResponse.transcript?.count, response.transcript?.count)
                XCTAssertEqual(response.transcript?.first?.content, expectedResponse.transcript?.first?.content)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as NSError, expectedError as NSError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetTranscript_Success() {
        let item = ConnectParticipantClientTypes.Item(content: "Hello")
        let response = GetTranscriptOutput(transcript: [item])
        performGetTranscriptTest(expectedResult: .success(response))
    }

    func testGetTranscript_Failure() {
        performGetTranscriptTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }

    // Test Get Transcript No Result
    func testGetTranscript_NoResultFailure() {
        mockClient.getTranscriptResult = .success(GetTranscriptOutput())
        let expectation = self.expectation(description: "GetTranscriptNoResult")

        awsClient.getTranscript(getTranscriptArgs: GetTranscriptInput()) { result in
            switch result {
            case .success(let response):
                XCTFail("Expected failure, got unexpected success: \(String(describing: response))")
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, "aws.amazon.com")
                XCTAssertEqual(error.code, 1001)
                XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as? String, "Failed to obtain transcript: No result or incorrect type returned from getTranscript.")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Test Get Transcript Incorrect Type
    func testGetTranscript_IncorrectTypeFailure() {
        let response = GetTranscriptOutput(transcript: nil)  // Simulate a response with no transcript
        mockClient.getTranscriptResult = .success(response)
        let expectation = self.expectation(description: "GetTranscriptIncorrectType")

        awsClient.getTranscript(getTranscriptArgs: GetTranscriptInput()) { result in
            switch result {
            case .success(let response):
                XCTFail("Expected failure, got unexpected success: \(String(describing: response))")
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, "aws.amazon.com")
                XCTAssertEqual(error.code, 1001)
                XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as? String, "Failed to obtain transcript: No result or incorrect type returned from getTranscript.")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // An empty transcript is valid and must not be treated as the nil case
    func testGetTranscript_EmptyTranscriptSucceeds() {
        mockClient.getTranscriptResult = .success(GetTranscriptOutput(transcript: []))
        let expectation = self.expectation(description: "GetTranscript empty")

        awsClient.getTranscript(getTranscriptArgs: GetTranscriptInput()) { result in
            guard case .success(let response) = result else {
                return XCTFail("An empty transcript should succeed")
            }
            XCTAssertEqual(response.transcript?.count, 0)
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetTranscript_PassesRequestThrough() {
        mockClient.getTranscriptResult = .success(GetTranscriptOutput(transcript: []))
        let args = GetTranscriptInput(
            connectionToken: dummyToken,
            maxResults: 15,
            scanDirection: .forward,
            sortOrder: .descending,
            startPosition: ConnectParticipantClientTypes.StartPosition(id: "item-1")
        )
        let expectation = self.expectation(description: "GetTranscript request")

        awsClient.getTranscript(getTranscriptArgs: args) { _ in expectation.fulfill() }
        waitForExpectations(timeout: timeout, handler: nil)

        let input = mockClient.lastGetTranscriptInput
        XCTAssertEqual(input?.connectionToken, dummyToken)
        XCTAssertEqual(input?.maxResults, 15)
        XCTAssertEqual(input?.scanDirection, .forward)
        XCTAssertEqual(input?.sortOrder, .descending)
        XCTAssertEqual(input?.startPosition?.id, "item-1")
    }

    // MARK: - Attachments

    func testStartAttachmentUpload_Success() {
        let response = StartAttachmentUploadOutput(attachmentId: "12345")
        mockClient.startAttachmentUploadResult = .success(response)
        let expectation = self.expectation(description: "StartAttachmentUpload succeeds")

        awsClient.startAttachmentUpload(connectionToken: dummyToken, contentType: "text/plain", attachmentName: "sample.txt", attachmentSizeInBytes: 1000) { result in
            switch result {
            case .success(let expectedResponse):
                XCTAssertEqual(expectedResponse.attachmentId, response.attachmentId)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testStartAttachmentUpload_Failure() {
        mockClient.startAttachmentUploadResult = .failure(MockAWSConnectParticipant.MockError.unexpected)
        let expectation = self.expectation(description: "StartAttachmentUpload fails")

        awsClient.startAttachmentUpload(connectionToken: dummyToken, contentType: "text/plain", attachmentName: "sample.txt", attachmentSizeInBytes: 1000) { result in
            switch result {
            case .success(let response):
                XCTFail("Expected failure, got unexpected success: \(String(describing: response))")
            case .failure(let error):
                XCTAssertEqual(error as NSError, MockAWSConnectParticipant.MockError.unexpected as NSError)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testStartAttachmentUpload_SendsExpectedRequest() {
        mockClient.startAttachmentUploadResult = .success(StartAttachmentUploadOutput(attachmentId: "12345"))
        let expectation = self.expectation(description: "StartAttachmentUpload request")

        awsClient.startAttachmentUpload(connectionToken: dummyToken, contentType: "text/plain", attachmentName: "sample.txt", attachmentSizeInBytes: 1000) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        let input = mockClient.lastStartAttachmentUploadInput
        XCTAssertEqual(input?.connectionToken, dummyToken)
        XCTAssertEqual(input?.contentType, "text/plain")
        XCTAssertEqual(input?.attachmentName, "sample.txt")
        XCTAssertEqual(input?.attachmentSizeInBytes, 1000)
    }

    func testCompleteAttachmentUpload_Success() {
        mockClient.completeAttachmnetUploadResult = .success(CompleteAttachmentUploadOutput())
        let expectation = self.expectation(description: "CompleteAttachmentUpload succeeds")

        awsClient.completeAttachmentUpload(connectionToken: dummyToken, attachmentIds: ["12345"]) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCompleteAttachmentUpload_Failure() {
        mockClient.completeAttachmnetUploadResult = .failure(MockAWSConnectParticipant.MockError.unexpected)
        let expectation = self.expectation(description: "CompleteAttachmentUpload fails")

        awsClient.completeAttachmentUpload(connectionToken: dummyToken, attachmentIds: ["12345"]) { result in
            switch result {
            case .success(let response):
                XCTFail("Expected failure, got unexpected success: \(String(describing: response))")
            case .failure(let error):
                XCTAssertEqual(error as NSError, MockAWSConnectParticipant.MockError.unexpected as NSError)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCompleteAttachmentUpload_SendsExpectedRequest() {
        mockClient.completeAttachmnetUploadResult = .success(CompleteAttachmentUploadOutput())
        let expectation = self.expectation(description: "CompleteAttachmentUpload request")

        awsClient.completeAttachmentUpload(connectionToken: dummyToken, attachmentIds: ["attachment-1"]) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        let input = mockClient.lastCompleteAttachmentUploadInput
        XCTAssertEqual(input?.connectionToken, dummyToken)
        XCTAssertEqual(input?.attachmentIds, ["attachment-1"])
    }

    func testGetAttachment_Success() {
        let response = GetAttachmentOutput(url: "https://www.example-s3-url.com")
        mockClient.getAttachmentResult = .success(response)
        let expectation = self.expectation(description: "GetAttachment succeeds")

        awsClient.getAttachment(connectionToken: dummyToken, attachmentId: "12345") { result in
            switch result {
            case .success(let expectedResponse):
                XCTAssertEqual(expectedResponse.url, response.url)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAttachment_Failure() {
        mockClient.getAttachmentResult = .failure(MockAWSConnectParticipant.MockError.unexpected)
        let expectation = self.expectation(description: "GetAttachment fails")

        awsClient.getAttachment(connectionToken: dummyToken, attachmentId: "12345") { result in
            switch result {
            case .success(let response):
                XCTFail("Expected failure, got unexpected success: \(String(describing: response))")
            case .failure(let error):
                XCTAssertEqual(error as NSError, MockAWSConnectParticipant.MockError.unexpected as NSError)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAttachment_SendsExpectedRequest() {
        mockClient.getAttachmentResult = .success(GetAttachmentOutput(url: "https://example.com"))
        let expectation = self.expectation(description: "GetAttachment request")

        awsClient.getAttachment(connectionToken: dummyToken, attachmentId: "attachment-1") { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        let input = mockClient.lastGetAttachmentInput
        XCTAssertEqual(input?.connectionToken, dummyToken)
        XCTAssertEqual(input?.attachmentId, "attachment-1")
    }

    // MARK: - Describe view

    func testDescribeView_Success() {
        let view = ConnectParticipantClientTypes.View(
            arn: "arn:aws:connect:us-east-1:123456789012:view/abc",
            content: ConnectParticipantClientTypes.ViewContent(template: "{}"),
            id: "view-1",
            name: "TestView",
            version: 3
        )
        mockClient.describeViewResult = .success(DescribeViewOutput(view: view))
        let expectation = self.expectation(description: "DescribeView succeeds")

        awsClient.describeView(connectionToken: dummyToken, viewToken: "viewToken") { result in
            guard case .success(let response) = result else {
                return XCTFail("Expected success")
            }
            XCTAssertEqual(response.view?.id, "view-1")
            XCTAssertEqual(response.view?.version, 3)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDescribeView_Failure() {
        mockClient.describeViewResult = .failure(MockAWSConnectParticipant.MockError.unexpected)
        let expectation = self.expectation(description: "DescribeView fails")

        awsClient.describeView(connectionToken: dummyToken, viewToken: "viewToken") { result in
            guard case .failure(let error) = result else {
                return XCTFail("Expected failure")
            }
            XCTAssertEqual(error as NSError, MockAWSConnectParticipant.MockError.unexpected as NSError)
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDescribeView_SendsExpectedRequest() {
        mockClient.describeViewResult = .success(DescribeViewOutput())
        let expectation = self.expectation(description: "DescribeView request")

        awsClient.describeView(connectionToken: dummyToken, viewToken: "view-token") { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        let input = mockClient.lastDescribeViewInput
        XCTAssertEqual(input?.connectionToken, dummyToken)
        XCTAssertEqual(input?.viewToken, "view-token")
    }

    // MARK: - Configuration and dispatch

    // An unconfigured client must fail cleanly rather than trap
    func testOperationFails_WhenClientNotConfigured() {
        let unconfigured = AWSClient()
        let expectation = self.expectation(description: "Unconfigured client fails")

        unconfigured.sendMessage(connectionToken: dummyToken, contentType: .plainText, message: "hi") { result in
            guard case .failure(let error) = result else {
                return XCTFail("Expected failure from an unconfigured client")
            }
            XCTAssertEqual(error as? AWSClient.AWSClientError, .failedToInitializeParticipantClient)
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Consumers update UI directly in these handlers, so completions must stay on the main thread
    func testCompletionsAreDeliveredOnMainThread() {
        mockClient.sendMessageResult = .success(SendMessageOutput())
        let expectation = self.expectation(description: "Completion on main thread")

        DispatchQueue.global(qos: .userInitiated).async {
            self.awsClient.sendMessage(connectionToken: self.dummyToken, contentType: .plainText, message: "hi") { _ in
                XCTAssertTrue(Thread.isMainThread, "AWSClient must deliver completions on the main thread")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testFailuresAreDeliveredOnMainThread() {
        mockClient.sendMessageResult = .failure(MockAWSConnectParticipant.MockError.unexpected)
        let expectation = self.expectation(description: "Failure on main thread")

        DispatchQueue.global(qos: .userInitiated).async {
            self.awsClient.sendMessage(connectionToken: self.dummyToken, contentType: .plainText, message: "hi") { _ in
                XCTAssertTrue(Thread.isMainThread, "AWSClient must deliver failures on the main thread")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
