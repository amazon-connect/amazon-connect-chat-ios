// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache 2.0

import XCTest
import Combine
@testable import AmazonConnectChatIOS

class WebsocketManagerTests: XCTestCase {
    var websocketManager: WebsocketManager!
    var mockWebSocketTask: MockWebSocketTask!
    var mockSession: URLSession!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        let url = URL(string: "wss://echo.websocket.org/")!
        websocketManager = WebsocketManager(wsUrl: url)
        mockWebSocketTask = MockWebSocketTask()
        websocketManager.websocketTask = mockWebSocketTask
        cancellables = []
    }

    override func tearDown() {
        websocketManager = nil
        mockWebSocketTask = nil
        cancellables = nil
        super.tearDown()
    }

    func testConnect() {
        let expectation = self.expectation(description: "WebSocket Connected")
        websocketManager.onConnected = {
            expectation.fulfill()
            self.websocketManager.onConnected = nil
        }
        websocketManager.connect()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDisconnect() {
        let expectation = self.expectation(description: "WebSocket Disconnected")
        websocketManager.onDisconnected = {
            expectation.fulfill()
            self.websocketManager.onDisconnected = nil

        }
        websocketManager.onConnected = {
            self.websocketManager.disconnect()
            self.websocketManager.onConnected = nil
        }
        websocketManager.connect()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSendWebSocketMessage() {
        websocketManager.sendWebSocketMessage(string: "Test Message")
        XCTAssertNotNil(mockWebSocketTask.sentMessage)
    }
    
    func testReceiveMessage() {
        let expectation = self.expectation(description: "WebSocket Message Received")
        let participant = "CUSTOMER"
        let text = "Test"
        let type = "MESSAGE"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, type: .message, participant: participant)))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let messageItem = item as? Message else {
                XCTFail("Expected message transcript item type")
                return
            }
            XCTAssertEqual(messageItem.text, text)
            XCTAssertEqual(messageItem.participant, participant)
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReceiveEvent_Joined() {
        let expectation = self.expectation(description: "WebSocket Joined Event Received")
        let participant = "CUSTOMER"
        let text = "Test"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .joined, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let eventItem = item as? Event else {
                XCTFail("Expected event transcript item type")
                return
            }
            XCTAssertEqual(eventItem.contentType, ContentType.joined.rawValue)
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReceiveEvent_Left() {
        let expectation = self.expectation(description: "WebSocket Left Event Received")
        let participant = "CUSTOMER"
        let text = "Test"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .left, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let eventItem = item as? Event else {
                XCTFail("Expected event transcript item type")
                return
            }
            XCTAssertEqual(eventItem.contentType, ContentType.left.rawValue)
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReceiveEvent_Typing() {
        let expectation = self.expectation(description: "WebSocket Typing Event Received")
        let participant = "CUSTOMER"
        let text = "Test"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .typing, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let eventItem = item as? Event else {
                XCTFail("Expected event transcript item type")
                return
            }
            XCTAssertEqual(eventItem.contentType, ContentType.typing.rawValue)
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReceiveEvent_Ended() {
        let expectation = self.expectation(description: "WebSocket End Event Received")
        let participant = "CUSTOMER"
        let text = "Test"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .ended, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let eventItem = item as? Event else {
                XCTFail("Expected event transcript item type")
                return
            }
            XCTAssertEqual(eventItem.contentType, ContentType.ended.rawValue)
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReceiveAttachment() {
        let expectation = self.expectation(description: "WebSocket Attachment Received")

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketAttachmentString()))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let attachmentItem = item as? Message else {
                XCTFail("Expected message transcript item type")
                return
            }
            XCTAssertEqual(attachmentItem.attachmentId, "attachment-id")
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReceiveMetadata() {
        let expectation = self.expectation(description: "WebSocket Metadata Received")

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleMetadataString()))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let metadataItem = item as? Metadata else {
                XCTFail("Expected metadata transcript item type")
                return
            }
            XCTAssertEqual(metadataItem.contentType, ContentType.metaData.rawValue)
            XCTAssertEqual(metadataItem.id, "message-id")
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReceiveEvent_TransferSucceeded() {
        let expectation = self.expectation(description: "WebSocket Transfer Succeeded Event Received")
        let participant = "AGENT"
        let text = "Transfer completed successfully"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .transferSucceeded, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let eventItem = item as? Event else {
                XCTFail("Expected event transcript item type")
                return
            }
            XCTAssertEqual(eventItem.contentType, ContentType.transferSucceeded.rawValue)
            XCTAssertEqual(eventItem.participant, participant)
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReceiveEvent_TransferFailed() {
        let expectation = self.expectation(description: "WebSocket Transfer Failed Event Received")
        let participant = "AGENT"
        let text = "Transfer failed"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .transferFailed, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let eventItem = item as? Event else {
                XCTFail("Expected event transcript item type")
                return
            }
            XCTAssertEqual(eventItem.contentType, ContentType.transferFailed.rawValue)
            XCTAssertEqual(eventItem.participant, participant)
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    private func createSampleWebSocketResultString(textContent:String = "Test", contentType:ContentType = .plainText, type:WebSocketMessageType = .message, participant:String = Constants.CUSTOMER) -> String {
        return "{\"content\":\"{\\\"AbsoluteTime\\\":\\\"2024-07-14T22:18:39.241Z\\\",\\\"Content\\\":\\\"\(textContent)\\\",\\\"ContentType\\\":\\\"\(contentType.rawValue)\\\",\\\"Id\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"Type\\\":\\\"\(type.rawValue)\\\",\\\"ParticipantId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"DisplayName\\\":\\\"Customer\\\",\\\"ParticipantRole\\\":\\\"\(participant)\\\",\\\"InitialContactId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"ContactId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\"}\",\"contentType\":\"application/json\",\"topic\":\"aws/chat\"}"
    }
    
    private func createSampleWebSocketAttachmentString() -> String {
        return "{\"content\":\"{\\\"AbsoluteTime\\\":\\\"2024-07-14T23:37:33.454Z\\\",\\\"Attachments\\\":[{\\\"ContentType\\\":\\\"text/plain\\\",\\\"AttachmentId\\\":\\\"attachment-id\\\",\\\"AttachmentName\\\":\\\"sample3.txt\\\",\\\"Status\\\":\\\"APPROVED\\\"}],\\\"Id\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"Type\\\":\\\"ATTACHMENT\\\",\\\"ParticipantId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"DisplayName\\\":\\\"Customer\\\",\\\"ParticipantRole\\\":\\\"CUSTOMER\\\",\\\"InitialContactId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"ContactId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\"}\",\"contentType\":\"application/json\",\"topic\":\"aws/chat\"}"
    }
    
    private func createSampleMetadataString() -> String {
        "{\"content\":\"{\\\"AbsoluteTime\\\":\\\"2024-07-14T23:41:28.821Z\\\",\\\"ContentType\\\":\\\"application/vnd.amazonaws.connect.event.message.metadata\\\",\\\"Id\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"Type\\\":\\\"MESSAGEMETADATA\\\",\\\"MessageMetadata\\\":{\\\"MessageId\\\":\\\"message-id\\\",\\\"Receipts\\\":[{\\\"DeliveredTimestamp\\\":\\\"2024-07-14T23:41:28.735Z\\\",\\\"ReadTimestamp\\\":\\\"2024-07-14T23:41:28.735Z\\\",\\\"RecipientParticipantId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\"}]}}\",\"contentType\":\"application/json\",\"topic\":\"aws/chat\"}"
    }

    // MARK: - Loosened message property tests (GitHub #109 / P382365182)

    func testHandleMessage_missingFields_defaultsToEmpty() {
        let innerJson: [String: Any] = ["Type": "MESSAGE"]
        let result = websocketManager.handleMessage(innerJson, [:])
        guard let msg = result as? Message else {
            XCTFail("Expected Message"); return
        }
        XCTAssertEqual(msg.id, "")
        XCTAssertEqual(msg.text, "")
        XCTAssertEqual(msg.participant, "")
        XCTAssertEqual(msg.displayName, "")
        XCTAssertEqual(msg.timeStamp, "")
        XCTAssertEqual(msg.contentType, "")
    }

    func testHandleMessage_completeFields_parsesCorrectly() {
        let innerJson: [String: Any] = [
            "ParticipantRole": "CUSTOMER",
            "Id": "msg-123",
            "Content": "Hello",
            "DisplayName": "Customer",
            "AbsoluteTime": "2026-02-28T00:00:00Z",
            "ContentType": "text/plain"
        ]
        let result = websocketManager.handleMessage(innerJson, [:])
        guard let msg = result as? Message else {
            XCTFail("Expected Message"); return
        }
        XCTAssertEqual(msg.id, "msg-123")
        XCTAssertEqual(msg.text, "Hello")
        XCTAssertEqual(msg.participant, "CUSTOMER")
    }

    func testHandleMessage_interactiveWithMetadataNoMessageId() {
        let innerJson: [String: Any] = [
            "ParticipantRole": "SYSTEM",
            "Id": "msg-456",
            "Content": "{\"templateType\":\"ListPicker\"}",
            "DisplayName": "BOT",
            "AbsoluteTime": "2026-02-28T00:00:00Z",
            "ContentType": "application/vnd.amazonaws.connect.message.interactive",
            "MessageMetadata": ["Receipts": []]
        ]
        let result = websocketManager.handleMessage(innerJson, [:])
        XCTAssertNotNil(result, "Should not crash on missing MessageId in MessageMetadata")
    }

    func testHandleMetadata_missingMessageId_fallsBackToOuterId() {
        let innerJson: [String: Any] = [
            "AbsoluteTime": "2026-02-28T00:00:00Z",
            "ContentType": "application/vnd.amazonaws.connect.event.message.metadata",
            "Id": "fallback-id",
            "Type": "MESSAGEMETADATA",
            "MessageMetadata": ["Receipts": []]
        ]
        let result = websocketManager.handleMetadata(innerJson, [:])
        guard let metadata = result as? Metadata else {
            XCTFail("Expected Metadata"); return
        }
        XCTAssertEqual(metadata.id, "fallback-id")
    }

    func testHandleMetadata_missingMessageIdAndOuterId_defaultsToEmpty() {
        let innerJson: [String: Any] = [
            "AbsoluteTime": "2026-02-28T00:00:00Z",
            "ContentType": "application/vnd.amazonaws.connect.event.message.metadata",
            "Type": "MESSAGEMETADATA",
            "MessageMetadata": ["Receipts": []]
        ]
        let result = websocketManager.handleMetadata(innerJson, [:])
        guard let metadata = result as? Metadata else {
            XCTFail("Expected Metadata"); return
        }
        XCTAssertEqual(metadata.id, "")
    }

    func testHandleMetadata_missingMessageMetadata_returnsNil() {
        let innerJson: [String: Any] = [
            "AbsoluteTime": "2026-02-28T00:00:00Z",
            "ContentType": "application/vnd.amazonaws.connect.event.message.metadata",
            "Type": "MESSAGEMETADATA"
        ]
        let result = websocketManager.handleMetadata(innerJson, [:])
        XCTAssertNil(result)
    }

    func testHandleMetadata_completeFields_parsesCorrectly() {
        let innerJson: [String: Any] = [
            "AbsoluteTime": "2026-02-28T00:00:00Z",
            "ContentType": "application/vnd.amazonaws.connect.event.message.metadata",
            "Type": "MESSAGEMETADATA",
            "MessageMetadata": [
                "MessageId": "meta-123",
                "Receipts": [["ReadTimestamp": "2026-02-28T00:00:00Z", "RecipientParticipantId": "p-1"]]
            ]
        ]
        let result = websocketManager.handleMetadata(innerJson, [:])
        guard let metadata = result as? Metadata else {
            XCTFail("Expected Metadata"); return
        }
        XCTAssertEqual(metadata.id, "meta-123")
        XCTAssertEqual(metadata.status, .Read)
    }

    func testHandleParticipantEvent_missingFields_defaultsToEmpty() {
        let innerJson: [String: Any] = [
            "ContentType": "application/vnd.amazonaws.connect.event.participant.joined",
            "Type": "EVENT"
        ]
        let result = websocketManager.handleParticipantEvent(innerJson, [:])
        guard let event = result as? Event else {
            XCTFail("Expected Event"); return
        }
        XCTAssertEqual(event.id, "")
        XCTAssertEqual(event.participant, "")
        XCTAssertEqual(event.displayName, "")
    }

    func testHandleTyping_missingFields_defaultsToEmpty() {
        let innerJson: [String: Any] = [
            "ContentType": "application/vnd.amazonaws.connect.event.typing",
            "Type": "EVENT"
        ]
        let result = websocketManager.handleTyping(innerJson, [:])
        guard let event = result as? Event else {
            XCTFail("Expected Event"); return
        }
        XCTAssertEqual(event.id, "")
        XCTAssertEqual(event.displayName, "")
    }

    func testHandleChatEnded_missingFields_defaultsToEmpty() {
        let innerJson: [String: Any] = [
            "ContentType": "application/vnd.amazonaws.connect.event.chat.ended",
            "Type": "EVENT"
        ]
        let result = websocketManager.handleChatEnded(innerJson, [:])
        guard let event = result as? Event else {
            XCTFail("Expected Event"); return
        }
        XCTAssertEqual(event.id, "")
        XCTAssertEqual(event.timeStamp, "")
    }

    func testHandleAttachment_missingFields_defaultsToEmpty() {
        let innerJson: [String: Any] = [
            "Type": "ATTACHMENT",
            "Attachments": [["AttachmentName": "file.pdf", "ContentType": "application/pdf", "AttachmentId": "a-1"]]
        ]
        let result = websocketManager.handleAttachment(innerJson, [:])
        guard let msg = result as? Message else {
            XCTFail("Expected Message"); return
        }
        XCTAssertEqual(msg.id, "")
        XCTAssertEqual(msg.participant, "")
        XCTAssertEqual(msg.displayName, "")
    }

    func testReceiveMetadata_missingMessageId_doesNotCrash() {
        let expectation = self.expectation(description: "WebSocket Metadata without MessageId")
        let metadataString = "{\"content\":\"{\\\"AbsoluteTime\\\":\\\"2024-07-14T23:41:28.821Z\\\",\\\"ContentType\\\":\\\"application/vnd.amazonaws.connect.event.message.metadata\\\",\\\"Id\\\":\\\"outer-id\\\",\\\"Type\\\":\\\"MESSAGEMETADATA\\\",\\\"MessageMetadata\\\":{\\\"Receipts\\\":[]}}\",\"contentType\":\"application/json\",\"topic\":\"aws/chat\"}"

        mockWebSocketTask.mockReceiveResult = .success(.string(metadataString))
        websocketManager.transcriptPublisher.sink { (item, shouldTrigger) in
            XCTAssertNotNil(item)
            guard let metadataItem = item as? Metadata else {
                XCTFail("Expected metadata transcript item type"); return
            }
            XCTAssertEqual(metadataItem.id, "outer-id")
            expectation.fulfill()
        }.store(in: &cancellables)
        websocketManager.receiveMessage()
        waitForExpectations(timeout: 1, handler: nil)
    }
}

// Mock WebSocket Task
class MockWebSocketTask: WebSocketTask {
    var sentMessage: URLSessionWebSocketTask.Message?
    var mockReceiveResult: Result<URLSessionWebSocketTask.Message, Error>?
    var numMessagesToReceive: Int = 1

    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void) {
        sentMessage = message
        completionHandler(nil)
    }

    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
        if numMessagesToReceive > 0 {
            numMessagesToReceive -= 1
            if let result = mockReceiveResult {
                completionHandler(result)
            }
        }

    }
    
    func resume() {}
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {}
}
