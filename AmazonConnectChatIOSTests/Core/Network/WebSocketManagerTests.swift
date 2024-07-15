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
        websocketManager.transcriptPublisher.sink { item in
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
        let expectation = self.expectation(description: "WebSocket Message Received")
        let participant = "CUSTOMER"
        let text = "Test"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .joined, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { item in
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
        let expectation = self.expectation(description: "WebSocket Message Received")
        let participant = "CUSTOMER"
        let text = "Test"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .left, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { item in
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
        let expectation = self.expectation(description: "WebSocket Message Received")
        let participant = "CUSTOMER"
        let text = "Test"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .typing, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { item in
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
        let expectation = self.expectation(description: "WebSocket Message Received")
        let participant = "CUSTOMER"
        let text = "Test"

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketResultString(textContent: text, contentType: .ended, type: .event, participant: participant)))
        websocketManager.transcriptPublisher.sink { item in
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
        let expectation = self.expectation(description: "WebSocket Message Received")

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleWebSocketAttachmentString()))
        websocketManager.transcriptPublisher.sink { item in
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
        let expectation = self.expectation(description: "WebSocket Message Received")

        mockWebSocketTask.mockReceiveResult = .success(.string(createSampleMetadataString()))
        websocketManager.transcriptPublisher.sink { item in
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
    
    private func createSampleWebSocketResultString(textContent:String = "Test", contentType:ContentType = .plainText, type:WebSocketMessageType = .message, participant:String = Constants.CUSTOMER) -> String {
        return "{\"content\":\"{\\\"AbsoluteTime\\\":\\\"2024-07-14T22:18:39.241Z\\\",\\\"Content\\\":\\\"\(textContent)\\\",\\\"ContentType\\\":\\\"\(contentType.rawValue)\\\",\\\"Id\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"Type\\\":\\\"\(type.rawValue)\\\",\\\"ParticipantId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"DisplayName\\\":\\\"Customer\\\",\\\"ParticipantRole\\\":\\\"\(participant)\\\",\\\"InitialContactId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"ContactId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\"}\",\"contentType\":\"application/json\",\"topic\":\"aws/chat\"}"
    }
    
    private func createSampleWebSocketAttachmentString() -> String {
        return "{\"content\":\"{\\\"AbsoluteTime\\\":\\\"2024-07-14T23:37:33.454Z\\\",\\\"Attachments\\\":[{\\\"ContentType\\\":\\\"text/plain\\\",\\\"AttachmentId\\\":\\\"attachment-id\\\",\\\"AttachmentName\\\":\\\"sample3.txt\\\",\\\"Status\\\":\\\"APPROVED\\\"}],\\\"Id\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"Type\\\":\\\"ATTACHMENT\\\",\\\"ParticipantId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"DisplayName\\\":\\\"Customer\\\",\\\"ParticipantRole\\\":\\\"CUSTOMER\\\",\\\"InitialContactId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"ContactId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\"}\",\"contentType\":\"application/json\",\"topic\":\"aws/chat\"}"
    }
    
    private func createSampleMetadataString() -> String {
        "{\"content\":\"{\\\"AbsoluteTime\\\":\\\"2024-07-14T23:41:28.821Z\\\",\\\"ContentType\\\":\\\"application/vnd.amazonaws.connect.event.message.metadata\\\",\\\"Id\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\",\\\"Type\\\":\\\"MESSAGEMETADATA\\\",\\\"MessageMetadata\\\":{\\\"MessageId\\\":\\\"message-id\\\",\\\"Receipts\\\":[{\\\"DeliveredTimestamp\\\":\\\"2024-07-14T23:41:28.735Z\\\",\\\"ReadTimestamp\\\":\\\"2024-07-14T23:41:28.735Z\\\",\\\"RecipientParticipantId\\\":\\\"abcdefgh-abcd-abcd-abcd-abcdefghijkl\\\"}]}}\",\"contentType\":\"application/json\",\"topic\":\"aws/chat\"}"
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
