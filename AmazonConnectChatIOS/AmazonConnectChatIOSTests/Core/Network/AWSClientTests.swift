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
        AWSClient.shared.getTranscriptRequest = { AWSConnectParticipantGetTranscriptRequest() }
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
    func testCreateParticipantConnectionSuccess() {
        let response = AWSConnectParticipantCreateParticipantConnectionResponse()!
        response.websocket = AWSConnectParticipantWebsocket()
        response.websocket?.url = "wss://example.com"
        response.connectionCredentials = AWSConnectParticipantConnectionCredentials()
        response.connectionCredentials?.connectionToken = dummyToken
        performCreateParticipantConnectionTest(expectedResult: .success(response))
    }
    
    // Test Create Participant Connection Failure
    func testCreateParticipantConnectionFailure() {
        performCreateParticipantConnectionTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Create Participant Connection Request Failure
    func testCreateParticipantConnectionRequestCreationFailure() {
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
    func testDisconnectParticipantConnectionSuccess() {
        performDisconnectParticipantConnectionTest(expectedResult: .success(nil))
    }
    
    // Test Disconnect Participant Connection Failure
    func testDisconnectParticipantConnectionFailure() {
        performDisconnectParticipantConnectionTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Disconnect Participant Connection Request Failure
    func testDisconnectParticipantConnectionRequestCreationFailure() {
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
    func testSendMessageSuccess() {
        performSendMessageTest(expectedResult: .success(nil))
    }
    
    // Test Send Message Failure
    func testSendMessageFailure() {
        performSendMessageTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Send Message Request Failure
    func testSendMessageRequestCreationFailure() {
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
    func testSendEventSuccess() {
        performSendEventTest(expectedResult: .success(nil))
    }
    
    // Test Send Event Failure
    func testSendEventFailure() {
        performSendEventTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Send Event Request Failure
    func testSendEventRequestCreationFailure() {
        performSendEventTest(expectedResult: .failure(AWSClient.AWSClientError.requestCreationFailed), simulateRequestFailure: true)
    }
    
    // Helper method for get transcript tests
    func performGetTranscriptTest(expectedResult: Result<AWSConnectParticipantGetTranscriptResponse, Error>, simulateRequestFailure: Bool = false) {
        if simulateRequestFailure {
            awsClient.getTranscriptRequest = { nil }
        } else {
            mockClient.getTranscriptResult = expectedResult
        }
        
        let expectation = self.expectation(description: "GetTranscript")
        
        awsClient.getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest()) { result in
            switch (expectedResult, result) {
            case (.success(let expectedResponse), .success(let items)):
                XCTAssertEqual(items.count, expectedResponse.transcript?.count)
                XCTAssertEqual(items.first?.content, expectedResponse.transcript?.first?.content)
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
    func testGetTranscriptSuccess() {
        let response = AWSConnectParticipantGetTranscriptResponse()!
        let item = AWSConnectParticipantItem()!
        item.content = "Hello"
        response.transcript = [item]
        performGetTranscriptTest(expectedResult: .success(response))
    }
    
    // Test Get Transcript Failure
    func testGetTranscriptFailure() {
        performGetTranscriptTest(expectedResult: .failure(MockAWSConnectParticipant.MockError.unexpected))
    }
    
    // Test Get Transcript Request Failure
    func testGetTranscriptRequestCreationFailure() {
        performGetTranscriptTest(expectedResult: .failure(AWSClient.AWSClientError.requestCreationFailed), simulateRequestFailure: true)
    }
    
    // Test Get Transcript No Result
    func testGetTranscriptNoResult() {
        mockClient.getTranscriptResult = .success(AWSConnectParticipantGetTranscriptResponse())
        let expectation = self.expectation(description: "GetTranscriptNoResult")
        
        awsClient.getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest()) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success")
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
    func testGetTranscriptIncorrectType() {
        let response = AWSConnectParticipantGetTranscriptResponse()!
        response.transcript = nil  // Simulate incorrect type
        mockClient.getTranscriptResult = .success(response)
        let expectation = self.expectation(description: "GetTranscriptIncorrectType")
        
        awsClient.getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest()) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success")
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, "aws.amazon.com")
                XCTAssertEqual(error.code, 1001)
                XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as? String, "Failed to obtain transcript: No result or incorrect type returned from getTranscript.")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
