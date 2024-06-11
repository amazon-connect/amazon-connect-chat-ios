// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import XCTest
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class ChatServiceTests: XCTestCase {
    var chatService: ChatService!
    var mockAWSClient: MockAWSClient!
    var mockConnectionDetailsProvider: MockConnectionDetailsProvider!
    var mockWebsocketManager: MockWebsocketManager!
    
    override func setUp() {
        super.setUp()
        setupMocks()
        setupChatService()
    }
    
    override func tearDown() {
        tearDownMocks()
        super.tearDown()
    }
    
    private func setupMocks() {
        mockAWSClient = MockAWSClient()
        mockConnectionDetailsProvider = MockConnectionDetailsProvider()
        mockWebsocketManager = MockWebsocketManager()
    }
    
    private func setupChatService() {
        chatService = ChatService(
            awsClient: mockAWSClient,
            connectionDetailsProvider: mockConnectionDetailsProvider,
            websocketManagerFactory: { _ in self.mockWebsocketManager }
        )
    }
    
    private func tearDownMocks() {
        chatService = nil
        mockAWSClient = nil
        mockConnectionDetailsProvider = nil
        mockWebsocketManager = nil
    }
    
    // Helper method to create chat details
    private func createChatDetails() -> ChatDetails {
        return ChatDetails(contactId: "testContactId", participantId: "testParticipantId", participantToken: "testParticipantToken")
    }
    
    // Helper method to create connection details
    private func createConnectionDetails() -> ConnectionDetails {
        return ConnectionDetails(websocketUrl: "wss://example.com", connectionToken: "mockConnectionToken", expiry: nil)
    }
    
    func testSetupWebSocket() {
        let chatDetails = createChatDetails()
        let connectionDetails = createConnectionDetails()
        mockAWSClient.createParticipantConnectionResult = .success(connectionDetails)
        mockConnectionDetailsProvider.updateChatDetails(newDetails: chatDetails)
        
        let expectationEvent = expectation(description: "Should receive event")
        let expectationTranscript = expectation(description: "Should receive transcript item")
        
        var receivedEvent: ChatEvent?
        var receivedTranscriptItem: TranscriptItem?
        
        let eventCancellable = chatService.subscribeToEvents { event in
            receivedEvent = event
            expectationEvent.fulfill()
        }
        
        let transcriptCancellable = chatService.subscribeToTranscriptItem { item in
            receivedTranscriptItem = item
            expectationTranscript.fulfill()
        }
        
        chatService.createChatSession(chatDetails: chatDetails) { success, error in
            XCTAssertTrue(success, "Chat session should be created successfully")
            XCTAssertNil(error, "Error should be nil")
            
            // Simulate WebSocket events
            self.mockWebsocketManager.eventPublisher.send(.connectionEstablished)
            let transcriptItem = TranscriptItem(timeStamp: "timestamp", contentType: "text/plain", serializedContent: ["content": "testContent"])
            self.mockWebsocketManager.transcriptPublisher.send(transcriptItem)
        }
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
            XCTAssertEqual(receivedEvent, .connectionEstablished, "Should receive the correct event")
            XCTAssertEqual(receivedTranscriptItem?.contentType, "text/plain", "Should receive the correct transcript item")
        }
        
        eventCancellable.cancel()
        transcriptCancellable.cancel()
    }
    
    func testSubscribeToEvents() {
        let receivedEvent = subscribeAndSendEvent(.connectionEstablished)
        XCTAssertEqual(receivedEvent, .connectionEstablished, "Should receive the correct event")
    }
    
    func testSubscribeToTranscriptItem() {
        let receivedItem = subscribeAndSendTranscriptItem(TranscriptItem(timeStamp: "timestamp", contentType: "text/plain", serializedContent: ["content": "testContent"]))
        XCTAssertEqual(receivedItem?.contentType, "text/plain", "Should receive the correct transcript item")
    }
    
    func testSubscribeToTranscriptList() {
        var receivedItems: [TranscriptItem] = []
        let expectation = self.expectation(description: "Should receive transcript list")
        
        var isExpectationFulfilled = false
        let cancellable = chatService.subscribeToTranscriptList { items in
            receivedItems = items
            if !isExpectationFulfilled {
                expectation.fulfill()
                isExpectationFulfilled = true
            }
        }
        
        let transcriptItem = TranscriptItem(timeStamp: "timestamp", contentType: "text/plain", serializedContent: ["content": "testContent"])
        chatService.transcriptListPublisher.send([transcriptItem])
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
            XCTAssertEqual(receivedItems.count, 1, "Should receive one transcript item")
            XCTAssertEqual(receivedItems.first?.contentType, "text/plain", "Should receive the correct transcript list")
            cancellable.cancel()
        }
    }
    
    func testCreateChatSession_Success() {
        let chatDetails = createChatDetails()
        let connectionDetails = createConnectionDetails()
        mockAWSClient.createParticipantConnectionResult = .success(connectionDetails)
        
        let expectation = self.expectation(description: "Chat session should be created successfully")
        
        chatService.createChatSession(chatDetails: chatDetails) { success, error in
            XCTAssertTrue(success, "Chat session should be created successfully")
            XCTAssertNil(error, "Error should be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testCreateChatSession_Failure() {
        let chatDetails = createChatDetails()
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        mockAWSClient.createParticipantConnectionResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Chat session creation should fail")
        
        chatService.createChatSession(chatDetails: chatDetails) { success, error in
            XCTAssertFalse(success, "Chat session should not be created successfully")
            XCTAssertEqual(error as NSError?, expectedError, "Should receive the expected error")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testDisconnectChatSession_Success() {
        let connectionDetails = createConnectionDetails()
        mockConnectionDetailsProvider.mockConnectionDetails = connectionDetails
        
        let expectation = self.expectation(description: "Chat session should be disconnected successfully")
        mockAWSClient.disconnectParticipantConnectionResult = .success(true)
        
        chatService.disconnectChatSession { success, error in
            XCTAssertTrue(success, "Chat session should be disconnected successfully")
            XCTAssertNil(error, "Error should be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testDisconnectChatSession_Failure() {
        let connectionDetails = createConnectionDetails()
        mockConnectionDetailsProvider.mockConnectionDetails = connectionDetails
        
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        mockAWSClient.disconnectParticipantConnectionResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Chat session disconnection should fail")
        
        chatService.disconnectChatSession { success, error in
            XCTAssertFalse(success, "Chat session should not be disconnected successfully")
            XCTAssertEqual(error as NSError?, expectedError, "Should receive the expected error")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testDisconnectChatSession_Failure_NoConnectionDetails() {
        mockConnectionDetailsProvider.mockConnectionDetails = nil
        
        let noConnectionDetailsError = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
        
        let expectation = self.expectation(description: "Chat session disconnection should fail due to no connection details")
        
        chatService.disconnectChatSession { success, error in
            XCTAssertFalse(success, "Chat session should not be disconnected successfully")
            XCTAssertEqual(error as NSError?, noConnectionDetailsError, "Should receive the expected error for no connection details")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendMessage_Success() {
        let message = "Test message"
        let contentType = ContentType.plainText
        let connectionDetails = createConnectionDetails()
        mockConnectionDetailsProvider.mockConnectionDetails = connectionDetails
        mockAWSClient.sendMessageResult = .success(true)
        
        let expectation = self.expectation(description: "Message should be sent successfully")
        
        chatService.sendMessage(contentType: contentType, message: message) { success, error in
            XCTAssertTrue(success, "Message should be sent successfully")
            XCTAssertNil(error, "Error should be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendMessage_Failure() {
        let message = "Test message"
        let contentType = ContentType.plainText
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let connectionDetails = createConnectionDetails()
        mockConnectionDetailsProvider.mockConnectionDetails = connectionDetails
        mockAWSClient.sendMessageResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Message sending should fail")
        
        chatService.sendMessage(contentType: contentType, message: message) { success, error in
            XCTAssertFalse(success, "Message should not be sent successfully")
            XCTAssertEqual(error as NSError?, expectedError, "Should receive the expected error")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendMessage_Failure_NoConnectionDetails() {
        mockConnectionDetailsProvider.mockConnectionDetails = nil
        
        let noConnectionDetailsError = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
        
        let expectation = self.expectation(description: "Message sending should fail due to no connection details")
        
        chatService.sendMessage(contentType: .plainText, message: "Test") { success, error in
            XCTAssertFalse(success, "Message should not be sent successfully")
            XCTAssertEqual(error as NSError?, noConnectionDetailsError, "Should receive the expected error for no connection details")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendEvent_Success() {
        let event = ContentType.typing
        let content = "Test event"
        let connectionDetails = createConnectionDetails()
        mockConnectionDetailsProvider.mockConnectionDetails = connectionDetails
        mockAWSClient.sendEventResult = .success(true)
        
        let expectation = self.expectation(description: "Event should be sent successfully")
        
        chatService.sendEvent(event: event, content: content) { success, error in
            XCTAssertTrue(success, "Event should be sent successfully")
            XCTAssertNil(error, "Error should be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendEvent_Failure() {
        let event = ContentType.typing
        let content = "Test event"
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let connectionDetails = createConnectionDetails()
        mockConnectionDetailsProvider.mockConnectionDetails = connectionDetails
        mockAWSClient.sendEventResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Event sending should fail")
        
        chatService.sendEvent(event: event, content: content) { success, error in
            XCTAssertFalse(success, "Event should not be sent successfully")
            XCTAssertEqual(error as NSError?, expectedError, "Should receive the expected error")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendEvent_Failure_NoConnectionDetails() {
        mockConnectionDetailsProvider.mockConnectionDetails = nil
        
        let noConnectionDetailsError = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
        
        let expectation = self.expectation(description: "Event sending should fail due to no connection details")
        
        chatService.sendEvent(event: .typing, content: "Test event") { success, error in
            XCTAssertFalse(success, "Event should not be sent successfully")
            XCTAssertEqual(error as NSError?, noConnectionDetailsError, "Should receive the expected error for no connection details")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testGetTranscript_Success() {
        let chatDetails = createChatDetails()
        let connectionDetails = createConnectionDetails()
        mockAWSClient.createParticipantConnectionResult = .success(connectionDetails)
        mockConnectionDetailsProvider.mockConnectionDetails = connectionDetails
        
        let transcriptItem = AWSConnectParticipantItem()
        transcriptItem!.content = "testContent"
        
        let response = AWSConnectParticipantGetTranscriptResponse()!
        response.transcript = [transcriptItem!]
        
        mockAWSClient.getTranscriptResult = .success(response)
        
        let expectation = self.expectation(description: "Transcript should be retrieved successfully")
        
        // Create the chat session to ensure WebSocket is set up
        chatService.createChatSession(chatDetails: chatDetails) { success, error in
            XCTAssertTrue(success, "Chat session should be created successfully")
            XCTAssertNil(error, "Error should be nil")
            
            // Get the transcript after the chat session is created
            self.chatService.getTranscript(scanDirection: .backward, sortOrder: .ascending, maxResults: 15, nextToken: nil, startPosition: nil) { result in
                switch result {
                case .success(let transcriptResponse):
                    XCTAssertEqual(transcriptResponse.transcript.count, 1, "Retrieved items should match expected items count")
                    XCTAssertEqual(transcriptResponse.transcript.first?.serializedContent?["content"] as! String, "testContent", "Retrieved content should match expected content")
                case .failure(let error):
                    XCTFail("Unexpected failure: \(error)")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1)
    }

    
    func testGetTranscript_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let connectionDetails = createConnectionDetails()
        mockConnectionDetailsProvider.mockConnectionDetails = connectionDetails
        mockAWSClient.getTranscriptResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Transcript retrieval should fail")
        
        chatService.getTranscript(scanDirection: .backward, sortOrder: .ascending, maxResults: 15, nextToken: nil, startPosition: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Unexpected success")
            case .failure(let error):
                XCTAssertEqual(error as NSError?, expectedError, "Should receive the expected error")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testGetTranscript_Failure_NoConnectionDetails() {
        mockConnectionDetailsProvider.mockConnectionDetails = nil
        
        let noConnectionDetailsError = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
        
        let expectation = self.expectation(description: "Transcript retrieval should fail due to no connection details")
        
        chatService.getTranscript(scanDirection: .backward, sortOrder: .ascending, maxResults: 15, nextToken: nil, startPosition: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Unexpected success")
            case .failure(let error):
                XCTAssertEqual(error as NSError?, noConnectionDetailsError, "Should receive the expected error for no connection details")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testRegisterNotificationListeners() {
        let expectation = self.expectation(description: "Should receive new WebSocket URL")
        
        let chatDetails = createChatDetails()
        mockConnectionDetailsProvider.updateChatDetails(newDetails: chatDetails)
        
        let newConnectionDetails = ConnectionDetails(websocketUrl: "wss://new-url.com", connectionToken: "newMockConnectionToken", expiry: nil)
        mockAWSClient.createParticipantConnectionResult = .success(newConnectionDetails)
        
        NotificationCenter.default.post(name: .requestNewWsUrl, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let updatedConnectionDetails = self.mockConnectionDetailsProvider.getConnectionDetails()
            XCTAssertEqual(updatedConnectionDetails?.websocketUrl, "wss://new-url.com", "WebSocket URL should be updated")
            XCTAssertEqual(updatedConnectionDetails?.connectionToken, "newMockConnectionToken", "Connection token should be updated")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}

extension ChatServiceTests {
    private func subscribeAndSendEvent(_ event: ChatEvent) -> ChatEvent? {
        var receivedEvent: ChatEvent?
        let expectation = self.expectation(description: "Should receive event")
        
        let cancellable = chatService.subscribeToEvents { event in
            receivedEvent = event
            expectation.fulfill()
        }
        
        chatService.eventPublisher.send(event)
        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
        return receivedEvent
    }
    
    private func subscribeAndSendTranscriptItem(_ item: TranscriptItem) -> TranscriptItem? {
        var receivedItem: TranscriptItem?
        let expectation = self.expectation(description: "Should receive transcript item")
        
        let cancellable = chatService.subscribeToTranscriptItem { item in
            receivedItem = item
            expectation.fulfill()
        }
        
        chatService.transcriptItemPublisher.send(item)
        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
        return receivedItem
    }
}
