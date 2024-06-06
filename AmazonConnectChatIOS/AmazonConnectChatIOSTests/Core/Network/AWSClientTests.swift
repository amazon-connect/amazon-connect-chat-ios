// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

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
        let config = GlobalConfig(region: .USEast1)
        AWSClient.shared.configure(with: config, participantClient: mockClient)
        
        // Reset state for awsClient
        resetAWSClientState()
    }
    
    override func tearDown() {
        // Reset state for awsClient
        resetAWSClientState()
        mockClient = nil
        super.tearDown()
    }
    
    // Helper function to reset AWSClient state
    private func resetAWSClientState() {
        AWSClient.shared.createParticipantConnectionRequest = { AWSConnectParticipantCreateParticipantConnectionRequest() }
        AWSClient.shared.disconnectParticipantRequest = { AWSConnectParticipantDisconnectParticipantRequest() }
        AWSClient.shared.sendMessageRequest = { AWSConnectParticipantSendMessageRequest() }
        AWSClient.shared.sendEventRequest = { AWSConnectParticipantSendEventRequest() }
    }
    
    
    // Test Configure Method
    func testConfigure() {
        // Given
        let config = GlobalConfig(region: .USEast1)
        
        // When
        awsClient.configure(with: config, participantClient: mockClient)
        
        // Then
        XCTAssertEqual(awsClient.region, .USEast1)
        XCTAssertTrue(awsClient.connectParticipantClient is MockAWSConnectParticipant)
    }
    
    // Helper method for participant connection tests
    func performCreateParticipantConnectionTest(expectedResult: Result<AWSConnectParticipantCreateParticipantConnectionResponse, Error>, simulateRequestFailure: Bool = false) {
        if simulateRequestFailure {
            awsClient.createParticipantConnectionRequest = { nil }
        } else {
            mockClient.createParticipantConnectionResult = expectedResult
        }
        
        let expectation = self.expectation(description: "CreateParticipantConnection")
        
        awsClient.createParticipantConnection(participantToken: dummyToken) { result in
            switch (expectedResult, result) {
            case (.success(let expectedResponse), .success(let details)):
                XCTAssertEqual(details.websocketUrl, expectedResponse.websocket?.url)
                XCTAssertEqual(details.connectionToken, expectedResponse.connectionCredentials?.connectionToken)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as? AWSClient.AWSClientError, expectedError as? AWSClient.AWSClientError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    // Test Create Participant Connection Success
    func testCreateParticipantConnection_Success() {
        let response = AWSConnectParticipantCreateParticipantConnectionResponse()!
        response.websocket = AWSConnectParticipantWebsocket()
        response.websocket?.url = "wss://example.com"
        response.connectionCredentials = AWSConnectParticipantConnectionCredentials()
        response.connectionCredentials?.connectionToken = dummyToken
        performCreateParticipantConnectionTest(expectedResult: .success(response))
    }
    
    // Test Create Participant Connection Failure
    func testCreateParticipantConnection_Failure() {
        performCreateParticipantConnectionTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Create Participant Connection Request Failure
    func testCreateParticipantConnection_RequestCreationFailure() {
        performCreateParticipantConnectionTest(expectedResult: .failure(AWSClient.AWSClientError.requestCreationFailed), simulateRequestFailure: true)
    }
    
    // Helper method for disconnect participant tests
    func performDisconnectParticipantConnectionTest(expectedResult: Result<AnyObject?, Error>, simulateRequestFailure: Bool = false) {
        if simulateRequestFailure {
            awsClient.disconnectParticipantRequest = { nil }
        } else {
            mockClient.disconnectParticipantResult = expectedResult
        }
        
        let expectation = self.expectation(description: "DisconnectParticipantConnection")
        
        awsClient.disconnectParticipantConnection(connectionToken: dummyToken) { result in
            switch (expectedResult, result) {
            case (.success(let expectedSuccess), .success(let success)):
                XCTAssertTrue(success)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as? AWSClient.AWSClientError, expectedError as? AWSClient.AWSClientError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    // Test Disconnect Participant Connection Success
    func testDisconnectParticipantConnection_Success() {
        performDisconnectParticipantConnectionTest(expectedResult: .success(nil))
    }
    
    // Test Disconnect Participant Connection Failure
    func testDisconnectParticipantConnection_Failure() {
        performDisconnectParticipantConnectionTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Disconnect Participant Connection Request Failure
    func testDisconnectParticipantConnection_RequestCreationFailure() {
        performDisconnectParticipantConnectionTest(expectedResult: .failure(AWSClient.AWSClientError.requestCreationFailed), simulateRequestFailure: true)
    }
    
    // Helper method for send message tests
    func performSendMessageTest(expectedResult: Result<AnyObject?, Error>, simulateRequestFailure: Bool = false) {
        if simulateRequestFailure {
            awsClient.sendMessageRequest = { nil }
        } else {
            mockClient.sendMessageResult = expectedResult
        }
        
        let expectation = self.expectation(description: "SendMessage")
        
        awsClient.sendMessage(connectionToken: dummyToken, contentType: .plainText, message: "Hello, world!") { result in
            switch (expectedResult, result) {
            case (.success(_), .success(let success)):
                XCTAssertTrue(success)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as? AWSClient.AWSClientError, expectedError as? AWSClient.AWSClientError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    // Test Send Message Success
    func testSendMessage_Success() {
        performSendMessageTest(expectedResult: .success(nil))
    }
    
    // Test Send Message Failure
    func testSendMessage_Failure() {
        performSendMessageTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Send Message Request Failure
    func testSendMessage_RequestCreationFailure() {
        performSendMessageTest(expectedResult: .failure(AWSClient.AWSClientError.requestCreationFailed), simulateRequestFailure: true)
    }
    
    // Helper method for send event tests
    func performSendEventTest(expectedResult: Result<AnyObject?, Error>, simulateRequestFailure: Bool = false) {
        if simulateRequestFailure {
            awsClient.sendEventRequest = { nil }
        } else {
            mockClient.sendEventResult = expectedResult
        }
        
        let expectation = self.expectation(description: "SendEvent")
        
        awsClient.sendEvent(connectionToken: dummyToken, contentType: .typing, content: "{}") { result in
            switch (expectedResult, result) {
            case (.success(_), .success(let success)):
                XCTAssertTrue(success)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as? AWSClient.AWSClientError, expectedError as? AWSClient.AWSClientError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    // Test Send Event Success
    func testSendEvent_Success() {
        performSendEventTest(expectedResult: .success(nil))
    }
    
    // Test Send Event Failure
    func testSendEvent_Failure() {
        performSendEventTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Send Event Request Failure
    func testSendEvent_RequestCreationFailure() {
        performSendEventTest(expectedResult: .failure(AWSClient.AWSClientError.requestCreationFailed), simulateRequestFailure: true)
    }
    
    // Helper method for get transcript tests
    func performGetTranscriptTest(expectedResult: Result<AWSConnectParticipantGetTranscriptResponse, Error>, simulateRequestFailure: Bool = false) {
        mockClient.getTranscriptResult = expectedResult

        let expectation = self.expectation(description: "GetTranscript")
        
        awsClient.getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest()) { result in
            switch (expectedResult, result) {
            case (.success(let expectedResponse), .success(let response)):
                XCTAssertEqual(expectedResponse.transcript?.count, response.transcript?.count)
                XCTAssertEqual(response.transcript?.first?.content, expectedResponse.transcript?.first?.content)
            case (.failure(let expectedError), .failure(let error)):
                XCTAssertEqual(error as? AWSClient.AWSClientError, expectedError as? AWSClient.AWSClientError)
            default:
                XCTFail("Unexpected result")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    // Test Get Transcript Success
    func testGetTranscript_Success() {
        let response = AWSConnectParticipantGetTranscriptResponse()!
        let item = AWSConnectParticipantItem()!
        item.content = "Hello"
        response.transcript = [item]
        performGetTranscriptTest(expectedResult: .success(response))
    }
    
    // Test Get Transcript Failure
    func testGetTranscript_Failure() {
        performGetTranscriptTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Get Transcript No Result
    func testGetTranscript_NoResultFailure() {
        mockClient.getTranscriptResult = .success(AWSConnectParticipantGetTranscriptResponse())
        let expectation = self.expectation(description: "GetTranscriptNoResult")
        
        awsClient.getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest()) { result in
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
        let response = AWSConnectParticipantGetTranscriptResponse()!
        response.transcript = nil  // Simulate incorrect type
        mockClient.getTranscriptResult = .success(response)
        let expectation = self.expectation(description: "GetTranscriptIncorrectType")
        
        awsClient.getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest()) { result in
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

    func testStartAttachmentUpload_Success() {
        let response = AWSConnectParticipantStartAttachmentUploadResponse()!
        response.attachmentId = "12345"
        mockClient.startAttachmentUploadResult = .success(response)
        let expectation = self.expectation(description: "StartAttachmentUpload")
        
        awsClient.startAttachmentUpload(connectionToken: dummyToken, contentType: "text/plain", attachmentName: "sample.txt", attachmentSizeInBytes: 1000) { result in
                switch result {
                case .success(let expectedResponse):
                    XCTAssertEqual(expectedResponse.attachmentId, response.attachmentId)
                    expectation.fulfill()
                case .failure(let error as NSError):
                    XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
                }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testStartAttachmentUpload_Failure() {
        mockClient.startAttachmentUploadResult = .failure(MockAWSConnectParticipant.MockError.unexpected)
        let expectation = self.expectation(description: "StartAttachmentUpload")
        
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
    
    func testCompleteAttachmentUpload_Success() {
        let response = AWSConnectParticipantCompleteAttachmentUploadResponse()!
        mockClient.completeAttachmnetUploadResult = .success(response)
        let expectation = self.expectation(description: "CompleteAttachmentUpload")
        
        awsClient.completeAttachmentUpload(connectionToken: dummyToken, attachmentIds: ["12345"]) { result in
                switch result {
                case .success(let expectedResponse):
                    expectation.fulfill()
                case .failure(let error as NSError):
                    XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
                }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testCompleteAttachmentUpload_Failure() {
        mockClient.completeAttachmnetUploadResult = .failure(MockAWSConnectParticipant.MockError.unexpected)
        let expectation = self.expectation(description: "CompleteAttachmentUpload")
        
        awsClient.completeAttachmentUpload(connectionToken: dummyToken, attachmentIds: ["12345"]) { result in
            switch result {
            case .success(let response):
                XCTFail("Expected failure, got unexpected success: \(String(describing: response))")
            case .failure(let error as NSError):
                XCTAssertEqual(error as NSError, MockAWSConnectParticipant.MockError.unexpected as NSError)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testGetAttachment_Success() {
        let response = AWSConnectParticipantGetAttachmentResponse()!
        response.url = "https://www.example-s3-url.com"
        mockClient.getAttachmentResult = .success(response)
        let expectation = self.expectation(description: "CompleteAttachmentUpload")
        
        awsClient.getAttachment(connectionToken: dummyToken, attachmentId: "12345") { result in
                switch result {
                case .success(let expectedResponse):
                    XCTAssertEqual(expectedResponse.url, response.url)
                    expectation.fulfill()
                case .failure(let error as NSError):
                    XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
                }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testGetAttachment_Failure() {
        mockClient.getAttachmentResult = .failure(MockAWSConnectParticipant.MockError.unexpected)
        let expectation = self.expectation(description: "GetAttachment")

        awsClient.getAttachment(connectionToken: dummyToken, attachmentId: "12345") { result in
                switch result {
                case .success(let response):
                    XCTFail("Expected failure, got unexpected success: \(String(describing: response))")
                case .failure(let error as NSError):
                    XCTAssertEqual(error as NSError, MockAWSConnectParticipant.MockError.unexpected as NSError)
                    expectation.fulfill()                }
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
