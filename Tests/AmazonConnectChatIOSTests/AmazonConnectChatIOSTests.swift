// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import AmazonConnectChatIOS

final class AmazonConnectChatIOSTests: XCTestCase {
    
    // MARK: - Helper Methods
    
    private func createEvent(
        text: String? = nil,
        timeStamp: String = "2024-08-01T21:00:00.000Z",
        contentType: String = "application/vnd.amazonaws.connect.event.participant.idle",
        messageId: String = "message-789",
        displayName: String? = "Test User",
        participant: String? = "CUSTOMER",
        eventDirection: MessageDirection = .Common,
        serializedContent: [String: Any] = [:]
    ) -> Event {
        return Event(
            text: text,
            timeStamp: timeStamp,
            contentType: contentType,
            messageId: messageId,
            displayName: displayName,
            participant: participant,
            eventDirection: eventDirection,
            serializedContent: serializedContent
        )
    }
    
    // MARK: - Event-Based Architecture Tests
    
    func testChatEventEquatable_ReadReceiptEvents() {
        // Given - ReadReceipt events are triggered via metadata processing
        let event1 = Event(
            text: "Message read",
            timeStamp: "2024-08-01T21:02:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.read",
            messageId: "msg-123",
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        let event2 = Event(
            text: "Message read",
            timeStamp: "2024-08-01T21:02:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.read",
            messageId: "msg-123",
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        let event3 = Event(
            text: "Message read",
            timeStamp: "2024-08-01T21:02:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.read",
            messageId: "msg-456",
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        
        let chatEvent1 = ChatEvent.readReceipt(event1)
        let chatEvent2 = ChatEvent.readReceipt(event2)
        let chatEvent3 = ChatEvent.readReceipt(event3)
        
        // Then
        XCTAssertEqual(chatEvent1, chatEvent2, "Same read receipt events should be equal")
        XCTAssertNotEqual(chatEvent1, chatEvent3, "Different message IDs should not be equal")
    }
    
    func testChatEventEquatable_DeliveredReceiptEvents() {
        // Given - DeliveredReceipt events are triggered via metadata processing
        let event1 = Event(
            text: "Message delivered",
            timeStamp: "2024-08-01T21:01:30.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.delivered",
            messageId: "msg-123",
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        let event2 = Event(
            text: "Message delivered",
            timeStamp: "2024-08-01T21:01:30.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.delivered",
            messageId: "msg-123",
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        let event3 = Event(
            text: "Message delivered",
            timeStamp: "2024-08-01T21:01:30.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.delivered",
            messageId: "msg-456",
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        
        let chatEvent1 = ChatEvent.deliveredReceipt(event1)
        let chatEvent2 = ChatEvent.deliveredReceipt(event2)
        let chatEvent3 = ChatEvent.deliveredReceipt(event3)
        
        // Then
        XCTAssertEqual(chatEvent1, chatEvent2, "Same delivered receipt events should be equal")
        XCTAssertNotEqual(chatEvent1, chatEvent3, "Different message IDs should not be equal")
    }
    
    func testChatEventEquatable_ParticipantEvents() {
        // Given
        let event1 = createEvent(displayName: "Customer", participant: "CUSTOMER")
        let event2 = createEvent(displayName: "Customer", participant: "CUSTOMER")
        let event3 = createEvent(displayName: "Agent", participant: "AGENT")
        
        let idleEvent1 = ChatEvent.participantIdle(event1)
        let idleEvent2 = ChatEvent.participantIdle(event2)
        let idleEvent3 = ChatEvent.participantIdle(event3)
        
        // Then
        XCTAssertEqual(idleEvent1, idleEvent2, "Same participant idle events should be equal")
        XCTAssertNotEqual(idleEvent1, idleEvent3, "Different participants should not be equal")
    }
    
    // MARK: - Content Type Tests
    
    func testContentTypeRawValues() {
        // Test that ContentType enum has correct raw values
        XCTAssertEqual(ContentType.typing.rawValue, "application/vnd.amazonaws.connect.event.typing")
        XCTAssertEqual(ContentType.messageDelivered.rawValue, "application/vnd.amazonaws.connect.event.message.delivered")
        XCTAssertEqual(ContentType.messageRead.rawValue, "application/vnd.amazonaws.connect.event.message.read")
        XCTAssertEqual(ContentType.metaData.rawValue, "application/vnd.amazonaws.connect.event.message.metadata")
        XCTAssertEqual(ContentType.joined.rawValue, "application/vnd.amazonaws.connect.event.participant.joined")
        XCTAssertEqual(ContentType.left.rawValue, "application/vnd.amazonaws.connect.event.participant.left")
        XCTAssertEqual(ContentType.ended.rawValue, "application/vnd.amazonaws.connect.event.chat.ended")
        XCTAssertEqual(ContentType.plainText.rawValue, "text/plain")
        XCTAssertEqual(ContentType.richText.rawValue, "text/markdown")
    }
    
    func testContentTypeToMessageType() {
        // Test ContentType to MessageType conversion
        XCTAssertEqual(ContentType.plainText.toMessageType(), .plainText)
        XCTAssertEqual(ContentType.richText.toMessageType(), .richText)
        XCTAssertEqual(ContentType.typing.toMessageType(), .typing)
        XCTAssertEqual(ContentType.connectionAcknowledged.toMessageType(), .connectionAcknowledged)
        XCTAssertEqual(ContentType.messageDelivered.toMessageType(), .messageDelivered)
        XCTAssertEqual(ContentType.messageRead.toMessageType(), .messageRead)
    }
}
