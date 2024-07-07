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
    let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
    
    override func setUp() {
        super.setUp()
        setupMocks()
        setupChatService()
    }
    
    override func tearDown() {
        tearDownMocks()
        tearDownTempFile()
        super.tearDown()
    }
    
    private func setupMocks() {
        mockAWSClient = MockAWSClient()
        mockConnectionDetailsProvider = MockConnectionDetailsProvider()
        mockWebsocketManager = MockWebsocketManager()
        mockConnectionDetailsProvider.mockConnectionDetails = createConnectionDetails()
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
    
    private func tearDownTempFile(url: URL? = nil) {
        let deleteUrl = url ?? TestConstants.testFileUrl
        do {
            if FileManager.default.fileExists(atPath: deleteUrl.path) {
                try FileManager.default.removeItem(at: deleteUrl)
                print("Temp file successfully cleared")
            }
        } catch {
            print("Failed to remove test file: \(error.localizedDescription)")
        }
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
        
        let expectationEvent = XCTestExpectation(description: "Should receive event")
        let expectationTranscript = XCTestExpectation(description: "Should receive transcript item")
        
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
            let transcriptItem = Message(participant: "Customer", text: "text", contentType: "text/plain", timeStamp: "timestamp", serializedContent: ["content": "test"])
            self.mockWebsocketManager.transcriptPublisher.send(transcriptItem)
        }
        
        let waiter = XCTWaiter()
        let result = waiter.wait(for: [expectationEvent, expectationTranscript], timeout: 1.0)
        
        switch result {
        case .completed:
            XCTAssertEqual(receivedEvent, .connectionEstablished, "Should receive the correct event")
            XCTAssertEqual(receivedTranscriptItem?.contentType, "text/plain", "Should receive the correct transcript item")
        default:
            XCTFail("Test failed with result: \(result)")
        }
        
        eventCancellable.cancel()
        transcriptCancellable.cancel()
    }

    
    func testSubscribeToEvents() {
        let receivedEvent = subscribeAndSendEvent(.connectionEstablished)
        XCTAssertEqual(receivedEvent, .connectionEstablished, "Should receive the correct event")
    }
    
    func testSubscribeToTranscriptItem() {
        let receivedItem = subscribeAndSendTranscriptItem(TranscriptItem(timeStamp: "timestamp", contentType: "text/plain", id: "12345", serializedContent: ["content": "testContent"]))
        XCTAssertEqual(receivedItem?.contentType, "text/plain", "Should receive the correct transcript item")
    }
    
//    func testSubscribeToTranscriptList() {
//        var receivedItems: [TranscriptItem] = []
//        let expectation = self.expectation(description: "Should receive transcript list")
//        
//        var isExpectationFulfilled = false
//        let cancellable = chatService.subscribeToTranscriptList { items in
//            receivedItems = items
//            if !isExpectationFulfilled {
//                expectation.fulfill()
//                isExpectationFulfilled = true
//            }
//        }
//        
//        let transcriptItem = TranscriptItem(timeStamp: "timestamp", contentType: "text/plain", id: "12345", serializedContent: ["content": "testContent"])
//        chatService.transcriptListPublisher.send([transcriptItem])
//        
//        waitForExpectations(timeout: 1) { error in
//            if let error = error {
//                XCTFail("Expectation failed with error: \(error)")
//            }
//            XCTAssertEqual(receivedItems.count, 1, "Should receive one transcript item")
//            XCTAssertEqual(receivedItems.first?.contentType, "text/plain", "Should receive the correct transcript list")
//            cancellable.cancel()
//        }
//    }
    
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
        mockAWSClient.createParticipantConnectionResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Chat session creation should fail")
        
        chatService.createChatSession(chatDetails: chatDetails) { success, error in
            XCTAssertFalse(success, "Chat session should not be created successfully")
            XCTAssertEqual(error as NSError?, self.expectedError, "Should receive the expected error")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testDisconnectChatSession_Success() {
        let expectation = self.expectation(description: "Chat session should be disconnected successfully")
        mockAWSClient.disconnectParticipantConnectionResult = .success(AWSConnectParticipantDisconnectParticipantResponse())

        chatService.disconnectChatSession { success, error in
            XCTAssertTrue(success, "Chat session should be disconnected successfully")
            XCTAssertNil(error, "Error should be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testDisconnectChatSession_Failure() {
        mockAWSClient.disconnectParticipantConnectionResult = .failure(expectedError)
        mockConnectionDetailsProvider.mockConnectionDetails = createConnectionDetails() // Ensure connection details are provided
        let expectation = self.expectation(description: "Chat session disconnection should fail")
        
        chatService.disconnectChatSession { success, error in
            XCTAssertFalse(success, "Chat session should not be disconnected successfully")
            XCTAssertEqual(error as NSError?, self.expectedError, "Should receive the expected error")
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
        mockAWSClient.sendMessageResult = .success(AWSConnectParticipantSendMessageResponse())
        
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
        mockAWSClient.sendMessageResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Message sending should fail")
        
        chatService.sendMessage(contentType: contentType, message: message) { success, error in
            XCTAssertFalse(success, "Message should not be sent successfully")
            XCTAssertEqual(error as NSError?, self.expectedError, "Should receive the expected error")
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
        mockAWSClient.sendEventResult = .success(AWSConnectParticipantSendEventResponse())
        
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
        mockAWSClient.sendEventResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Event sending should fail")
        
        chatService.sendEvent(event: event, content: content) { success, error in
            XCTAssertFalse(success, "Event should not be sent successfully")
            XCTAssertEqual(error as NSError?, self.expectedError, "Should receive the expected error")
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
    
    func testSendEvent_TypingEventThrottling() {
        let event = ContentType.typing
        let content = "Test event"
        mockAWSClient.sendEventResult = .success(AWSConnectParticipantSendEventResponse())
        
        let expectation = self.expectation(description: "Typing event should only be sent once if two typing events occur")
        
        chatService.sendEvent(event: event, content: content) { success, error in
            XCTAssertTrue(success, "Event should be sent successfully")
            XCTAssertNil(error, "Error should be nil")
            XCTAssertEqual(self.mockAWSClient.numTypingEventCalled, 1)
        }
        chatService.sendEvent(event: event, content: content) { success, error in
            XCTAssertTrue(success, "Event should be sent successfully")
            XCTAssertNil(error, "Error should be nil")
            XCTAssertEqual(self.mockAWSClient.numTypingEventCalled, 1)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendMessageReceipt_Success() {
        let expectation = self.expectation(description: "SendMessageReceipt succeeds")
        
        let mockChatService = MockChatService()
        mockChatService.mockSendMessageReceipt = false
        
        let mockMessageReceiptsManager = MockMessageReceiptsManager()
        let pendingMessageReceipts = PendingMessageReceipts(readReceiptMessageId: "67890", deliveredReceiptMessageId: "12345")
        
        mockMessageReceiptsManager.throttleAndSendMessageReceiptResult = .success(pendingMessageReceipts)
        mockChatService.messageReceiptsManager = mockMessageReceiptsManager
        mockChatService.sendPendingMessageReceiptsResult = .success(.messageRead)
        
        
        
        mockChatService.sendMessageReceipt(event: .messageRead, messageId: "12345") { result in
            switch result {
            case .success:
                XCTAssertEqual(mockMessageReceiptsManager.numThrottleAndSendMessageReceiptCalled, 1)
                XCTAssertEqual(mockChatService.numSendPendingMessageReceiptsCalled, 1)
                expectation.fulfill()
                break
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSendMessageReceipt_MessageReceiptsManagerFailure() {
        let expectation = self.expectation(description: "SendMessageReceipt fails when throttleAndSendMessageReceipt fails")
        
        let mockChatService = MockChatService()
        mockChatService.mockSendMessageReceipt = false
        let mockMessageReceiptsManager = MockMessageReceiptsManager()
        mockMessageReceiptsManager.throttleAndSendMessageReceiptResult = .failure(expectedError)
        mockChatService.messageReceiptsManager = mockMessageReceiptsManager
        
        
        mockChatService.sendMessageReceipt(event: .messageRead, messageId: "12345") { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got unexpected success")
                break
            case .failure(let error):
                XCTAssertEqual(mockMessageReceiptsManager.numThrottleAndSendMessageReceiptCalled, 1)
                XCTAssertEqual(mockChatService.numSendPendingMessageReceiptsCalled, 0)
                XCTAssertEqual(error as NSError, self.expectedError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSendMessageReceipt_SendPendingMessagesFailure() {
        let expectation = self.expectation(description: "SendMessageReceipt fails when sendPendingMessageReceipts fails")
        
        let mockChatService = MockChatService()
        mockChatService.mockSendMessageReceipt = false
        
        let mockMessageReceiptsManager = MockMessageReceiptsManager()
        var pendingMessageReceipts = PendingMessageReceipts(readReceiptMessageId: "67890", deliveredReceiptMessageId: "12345")
        
        mockMessageReceiptsManager.throttleAndSendMessageReceiptResult = .success(pendingMessageReceipts)
        mockChatService.messageReceiptsManager = mockMessageReceiptsManager
        mockChatService.sendPendingMessageReceiptsResult = .failure(expectedError)
        
        
        mockChatService.sendMessageReceipt(event: .messageRead, messageId: "12345") { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got unexpected success")
                break
            case .failure(let error):
                XCTAssertEqual(mockMessageReceiptsManager.numThrottleAndSendMessageReceiptCalled, 1)
                XCTAssertEqual(mockChatService.numSendPendingMessageReceiptsCalled, 1)
                XCTAssertEqual(error as NSError, self.expectedError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSendPendingMessageReceipts_ReadSucccess() {
        let expectation = self.expectation(description: "SendPendingMessageReceipts read receipt succeeds")
        
        let mockChatService = MockChatService()
        mockChatService.mockSendPendingMessageReceipts = false
        mockChatService.sendEventResult = (true, nil)
        var pendingMessageReceipts = PendingMessageReceipts(readReceiptMessageId: "67890")
        
        mockChatService.sendPendingMessageReceipts(pendingMessageReceipts: pendingMessageReceipts) { result in
            switch result {
            case .success(let messageReceiptType):
                XCTAssertEqual(mockChatService.numSendEventCalled, 1)
                XCTAssertEqual(messageReceiptType, .messageRead)
                expectation.fulfill()
                break
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSendPendingMessageReceipts_DeliveredSucccess() {
        let expectation = self.expectation(description: "SendPendingMessageReceipts delivered receipt succeeds")
        
        let mockChatService = MockChatService()
        mockChatService.mockSendPendingMessageReceipts = false
        mockChatService.sendEventResult = (true, nil)
        var pendingMessageReceipts = PendingMessageReceipts(deliveredReceiptMessageId: "12345")
        
        mockChatService.sendPendingMessageReceipts(pendingMessageReceipts: pendingMessageReceipts) { result in
            switch result {
            case .success(let messageReceiptType):
                XCTAssertEqual(mockChatService.numSendEventCalled, 1)
                XCTAssertEqual(messageReceiptType, .messageDelivered)
                expectation.fulfill()
                break
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSendPendingMessageReceipts_ReadDeliveredSucccess() {
        let expectation = self.expectation(description: "SendPendingMessageReceipts delivered receipt succeeds")
        
        let mockChatService = MockChatService()
        mockChatService.mockSendPendingMessageReceipts = false
        mockChatService.sendEventResult = (true, nil)
        var pendingMessageReceipts = PendingMessageReceipts(readReceiptMessageId: "67890", deliveredReceiptMessageId: "12345")
        
        var readReceiptReceived = false
        var deliveredReceiptReceived = false
        
        mockChatService.sendPendingMessageReceipts(pendingMessageReceipts: pendingMessageReceipts) { result in
            switch result {
            case .success(let messageReceiptType):
                if messageReceiptType == .messageDelivered {
                    if deliveredReceiptReceived {
                        XCTFail("Unexpectedly received two delivered receipts")
                    }
                    deliveredReceiptReceived = true
                } else if messageReceiptType == .messageRead {
                    if readReceiptReceived {
                        XCTFail("Unexpectedly received two read receipts")
                    }
                    readReceiptReceived = true
                }
                if readReceiptReceived && deliveredReceiptReceived {
                    expectation.fulfill()
                }
                break
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testSendPendingMessageReceipts_Failure() {
        let expectation = self.expectation(description: "SendPendingMessageReceipts fails")
        
        let mockChatService = MockChatService()
        mockChatService.mockSendPendingMessageReceipts = false
        mockChatService.sendEventResult = (false, expectedError)
        var pendingMessageReceipts = PendingMessageReceipts(deliveredReceiptMessageId: "12345")
        
        mockChatService.sendPendingMessageReceipts(pendingMessageReceipts: pendingMessageReceipts) { result in
            switch result {
            case .success(let messageReceiptType):
                XCTFail("Expected failure, got unexpected success: \(String(describing: messageReceiptType))")
                break
            case .failure(let error):
                XCTAssertEqual(mockChatService.numSendEventCalled, 1)
                XCTAssertEqual(error as NSError, self.expectedError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testGetTranscript_Success() {
        let chatDetails = createChatDetails()
        
        mockAWSClient.createParticipantConnectionResult = .success(createConnectionDetails())
        
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
        mockAWSClient.getTranscriptResult = .failure(expectedError)
        
        let expectation = self.expectation(description: "Transcript retrieval should fail")
        
        chatService.getTranscript(scanDirection: .backward, sortOrder: .ascending, maxResults: 15, nextToken: nil, startPosition: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Unexpected success")
            case .failure(let error):
                XCTAssertEqual(error as NSError?, self.expectedError, "Should receive the expected error")
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
    
    func testSendAttachment_Success() {
        let expectation = self.expectation(description: "SendAttachment succeeds")
        TestUtils.writeSampleTextToUrl(url: TestConstants.testFileUrl)
        
        let mockAttachmentManager = MockChatService()
        let mockAPIClient = MockAPIClient()
        mockAttachmentManager.apiClient = mockAPIClient
        mockAttachmentManager.mockSendAttachment = false
        
        let mockResponse = AWSConnectParticipantStartAttachmentUploadResponse()
        mockResponse!.attachmentId = "mockAttachmentId"
        mockAttachmentManager.startAttachmentUploadResult = .success(mockResponse!)
        mockAttachmentManager.completeAttachmentUploadResult = (true, nil)
        
        mockAttachmentManager.sendAttachment(file: TestConstants.testFileUrl) { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            XCTAssertEqual(mockAttachmentManager.numStartAttachmentUploadCalled, 1)
            XCTAssertTrue(mockAPIClient.uploadAttachmentCalled)
            XCTAssertEqual(mockAttachmentManager.numCompleteAttachmentUploadCalled, 1)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSendAttachment_InvalidMimeFailure() {
        let expectation = self.expectation(description: "SendAttachment fails due to invalid mime type")
        let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sample.xyz")
        let fileContents = "Sample text file contents"
        
        do {
            try fileContents.write(to: fileUrl, atomically: true, encoding: .utf8)
            print("File created successfully at: \(TestConstants.testFileUrl.path)")
        } catch {
            print("Failed to create file: \(error.localizedDescription)")
            return
        }
        let mockAttachmentManager = MockChatService()
        let mockAPIClient = MockAPIClient()
        mockAttachmentManager.apiClient = mockAPIClient
        mockAttachmentManager.mockSendAttachment = false
        mockAttachmentManager.sendAttachment(file: fileUrl) { success, error in
            self.tearDownTempFile(url: fileUrl)
            XCTAssertFalse(success)
            XCTAssertEqual(error?.localizedDescription, "Could not parse MIME type from file URL")
            XCTAssertEqual(mockAttachmentManager.numStartAttachmentUploadCalled, 0)
            XCTAssertFalse(mockAPIClient.uploadAttachmentCalled)
            XCTAssertEqual(mockAttachmentManager.numCompleteAttachmentUploadCalled, 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSendAttachment_UnsupportedMimeFailure() {
        let expectation = self.expectation(description: "Send Attachment fails due to unsupported mime type")
        let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sample.webp")
        let fileContents = "Sample text file contents"
        
        do {
            try fileContents.write(to: fileUrl, atomically: true, encoding: .utf8)
            print("File created successfully at: \(TestConstants.testFileUrl.path)")
        } catch {
            print("Failed to create file: \(error.localizedDescription)")
            return
        }
        let mockAttachmentManager = MockChatService()
        let mockAPIClient = MockAPIClient()
        mockAttachmentManager.apiClient = mockAPIClient
        mockAttachmentManager.mockSendAttachment = false
        mockAttachmentManager.sendAttachment(file: fileUrl) { success, error in
            self.tearDownTempFile(url: fileUrl)
            XCTAssertFalse(success)
            XCTAssertEqual(error?.localizedDescription, "image/webp is not a supported file type")
            XCTAssertEqual(mockAttachmentManager.numStartAttachmentUploadCalled, 0)
            XCTAssertFalse(mockAPIClient.uploadAttachmentCalled)
            XCTAssertEqual(mockAttachmentManager.numCompleteAttachmentUploadCalled, 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSendAttachment_InvalidFileSizeFailure() {
        let expectation = self.expectation(description: "SendAttachment fails due to invalid file size")
        
        let mockAttachmentManager = MockChatService()
        let mockAPIClient = MockAPIClient()
        mockAttachmentManager.apiClient = mockAPIClient
        mockAttachmentManager.mockSendAttachment = false
        mockAttachmentManager.sendAttachment(file: TestConstants.testFileUrl) { success, error in
            XCTAssertFalse(success)
            XCTAssertEqual(error?.localizedDescription, "Could not get valid file size")
            XCTAssertEqual(mockAttachmentManager.numStartAttachmentUploadCalled, 0)
            XCTAssertFalse(mockAPIClient.uploadAttachmentCalled)
            XCTAssertEqual(mockAttachmentManager.numCompleteAttachmentUploadCalled, 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testStartAttachmentUpload_Success() {
        let expectation = self.expectation(description: "StartAttachmentUpload succeeds")
        let response = AWSConnectParticipantStartAttachmentUploadResponse()
        mockAWSClient.startAttachmentUploadResult = .success(response!)
        
        chatService.startAttachmentUpload(contentType: "text/plain", attachmentName: "sample.txt", attachmentSizeInBytes: 1000) { result in
            switch result {
            case .success(let startAttachmentResponse):
                XCTAssertEqual(startAttachmentResponse, response)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testStartAttachmentUpload_Failure() {
        let expectation = self.expectation(description: "StartAttachmentUpload fails")
        mockAWSClient.startAttachmentUploadResult = .failure(expectedError)
        
        chatService.startAttachmentUpload(contentType: "text/plain", attachmentName: "sample.txt", attachmentSizeInBytes: 1000) { result in
            switch result {
            case .success(let startAttachmentResponse):
                XCTFail("Expected failure, got unexpected success: \(String(describing: startAttachmentResponse))")
            case .failure(let error):
                XCTAssertEqual(error as NSError?, self.expectedError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCompleteAttachmentUpload_Success() {
        let expectation = self.expectation(description: "CompleteAttachmentUpload succeeds")
        let response = AWSConnectParticipantCompleteAttachmentUploadResponse()
        mockAWSClient.completeAttachmentUploadResult = .success(response!)
        
        chatService.completeAttachmentUpload(attachmentIds: ["12345"]) { success, error in
            if success {
                expectation.fulfill()
            } else if error != nil {
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            } else {
                XCTFail("Expected success, got unexpected result")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCompleteAttachmentUpload_Failure() {
        let expectation = self.expectation(description: "CompleteAttachmentUpload fails")
        mockAWSClient.completeAttachmentUploadResult = .failure(expectedError)
        
        chatService.completeAttachmentUpload(attachmentIds: ["12345"]) { success, error in
            if success {
                XCTFail("Expected success, got unexpected success")
            } else if error != nil {
                XCTAssertEqual(error as NSError?, self.expectedError)
                expectation.fulfill()
            } else {
                XCTFail("Expected success, got unexpected result")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testGetAttachmentDownloadUrl_Success() {
        let expectation = self.expectation(description: "GetAttachmentDownloadUrl succeeds")
        guard let response = AWSConnectParticipantGetAttachmentResponse() else {
            XCTFail("AWSConnectParticipantGetAttachmentResponse returned nil")
            return
        }
        
        response.url = "https://www.test-endpoint.com"
        mockAWSClient.getAttachmentResult = .success(response)
        
        
        chatService.getAttachmentDownloadUrl(attachmentId: "12345") { result in
            switch result {
            case .success(let url):
                XCTAssertEqual(url.absoluteString, response.url)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testGetAttachmentDownloadUrl_Failure() {
        let expectation = self.expectation(description: "GetAttachmentDownloadUrl fails")
        
        guard let response = AWSConnectParticipantGetAttachmentResponse() else {
            XCTFail("AWSConnectParticipantGetAttachmentResponse returned nil")
            return
        }
        
        response.url = "https://www.test-endpoint.com"
        mockAWSClient.getAttachmentResult = .failure(expectedError)
        
        
        chatService.getAttachmentDownloadUrl(attachmentId: "12345") { result in
            switch result {
            case .success(let url):
                XCTFail("Expected failure, got unexpected success: \(url.absoluteString)")
            case .failure(let error):
                XCTAssertEqual(error as NSError, self.expectedError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testDownloadAttachment_Success() {
        let expectation = self.expectation(description: "downloadAttachment succeeds")
        guard let response = AWSConnectParticipantGetAttachmentResponse() else {
            XCTFail("AWSConnectParticipantGetAttachmentResponse returned nil")
            return
        }
        
        response.url = "https://www.test-endpoint.com"
        mockAWSClient.getAttachmentResult = .success(response)
        
        let mockAttachmentManager = MockChatService(
            awsClient: mockAWSClient,
            connectionDetailsProvider: mockConnectionDetailsProvider,
            websocketManagerFactory: { _ in self.mockWebsocketManager }
        )
        
        let sampleUrlString = "https://www.example.com"
        let sampleUrl = URL(string: sampleUrlString)!
        
        mockAttachmentManager.mockDownloadAttachment = false
        mockAttachmentManager.getAttachmentDownloadUrlResult = .success(sampleUrl)
        
        mockAttachmentManager.downloadFileResult = (sampleUrl, nil)
        
        mockAttachmentManager.downloadAttachment(attachmentId: "12345", filename: "sample.txt") { result in
            switch result {
            case .success(let url):
                XCTAssertEqual(url.absoluteString, sampleUrlString)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDownloadAttachment_Failure() {
        let expectation = self.expectation(description: "StartAttachmentUpload fails")
        
        mockAWSClient.getAttachmentResult = .failure(expectedError)
        
        chatService.downloadAttachment(attachmentId: "12345", filename: "sample.txt") { result in
            switch result {
            case .success(let url):
                XCTFail("Expected failure, got unexpected success: \(url.absoluteString)")
            case .failure(let error):
                XCTAssertEqual(error as NSError, self.expectedError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDownloadFile_Success() {
        let expectation = self.expectation(description: "DownloadFile succeeds")
        
        TestUtils.writeSampleTextToUrl(url: TestConstants.testFileUrl)
        
        let mockUrlSession = MockURLSession()
        mockUrlSession.mockUrlResult = TestConstants.testFileUrl
        chatService.urlSession = mockUrlSession
        
        var filename = "sample2.txt"
        
        var expectedLocalUrl = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        chatService.downloadFile(url: TestConstants.testFileUrl, filename: filename) { (localUrl, error) in
            if let localUrl = localUrl {
                XCTAssertEqual(localUrl, expectedLocalUrl)
                expectation.fulfill()
            } else if let error = error {
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDownloadFile_ErrorFailure() {
        let expectation = self.expectation(description: "DownloadFile fails")
        
        TestUtils.writeSampleTextToUrl(url: TestConstants.testFileUrl)
        
        let mockUrlSession = MockURLSession()
        mockUrlSession.mockError = expectedError
        chatService.urlSession = mockUrlSession
        
        chatService.downloadFile(url: TestConstants.testFileUrl, filename: "sample2.txt") { (localUrl, error) in
            if let localUrl = localUrl {
                XCTFail("Expected failure, got unexpected success: \(localUrl.absoluteString)")
                expectation.fulfill()
            } else if let error = error {
                XCTAssertEqual(error as NSError, self.expectedError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDownloadFile_NoFileFailure() {
        let expectation = self.expectation(description: "DownloadFile fails due to no file")
        
        let mockUrlSession = MockURLSession()
        chatService.urlSession = mockUrlSession
        
        chatService.downloadFile(url: TestConstants.testFileUrl, filename: "sample2.txt") { (localUrl, error) in
            if let localUrl = localUrl {
                XCTFail("Expected failure, got unexpected success: \(localUrl.absoluteString)")
                expectation.fulfill()
            } else if let error = error {
                XCTAssertEqual(error.localizedDescription, "No file found at URL")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
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
