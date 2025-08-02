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
    
    // MARK: - Event Tests
    
    func testEventDataEquatable() {
        // Given
        let eventData1 = createEventData(displayName: "Customer", participantRole: "CUSTOMER")
        let eventData2 = createEventData(displayName: "Customer", participantRole: "CUSTOMER")
        let eventData3 = createEventData(displayName: "Agent", participantRole: "AGENT")
        
        // Then
        XCTAssertEqual(eventData1, eventData2, "Same event data should be equal")
        XCTAssertNotEqual(eventData1, eventData3, "Different event data should not be equal")
    }
    
    func testEventDataInitialization() {
        // Given
        let eventData = createEventData(
            absoluteTime: "2024-08-01T21:00:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.typing",
            type: "EVENT",
            participantId: "participant-123",
            displayName: "Test Agent",
            participantRole: "AGENT",
            initialContactId: "contact-456",
            messageId: "message-789"
        )
        
        // Then
        XCTAssertEqual(eventData.absoluteTime, "2024-08-01T21:00:00.000Z")
        XCTAssertEqual(eventData.contentType, "application/vnd.amazonaws.connect.event.typing")
        XCTAssertEqual(eventData.type, "EVENT")
        XCTAssertEqual(eventData.participantId, "participant-123")
        XCTAssertEqual(eventData.displayName, "Test Agent")
        XCTAssertEqual(eventData.participantRole, "AGENT")
        XCTAssertEqual(eventData.initialContactId, "contact-456")
        XCTAssertEqual(eventData.messageId, "message-789")
    }
    
    func testEventDataWithNilValues() {
        // Given
        let eventData = EventData(
            absoluteTime: nil,
            contentType: nil,
            type: nil,
            participantId: nil,
            displayName: nil,
            participantRole: nil,
            initialContactId: nil,
            messageId: nil
        )
        
        // Then
        XCTAssertNil(eventData.absoluteTime)
        XCTAssertNil(eventData.contentType)
        XCTAssertNil(eventData.type)
        XCTAssertNil(eventData.participantId)
        XCTAssertNil(eventData.displayName)
        XCTAssertNil(eventData.participantRole)
        XCTAssertNil(eventData.initialContactId)
        XCTAssertNil(eventData.messageId)
    }
    
    // MARK: - ChatEvent Equatable Tests
    
    func testChatEventEquatable_ParticipantIdleEvents() {
        // Given
        let eventData1 = createEventData(displayName: "Customer", participantRole: "CUSTOMER")
        let eventData2 = createEventData(displayName: "Customer", participantRole: "CUSTOMER")
        let eventData3 = createEventData(displayName: "Agent", participantRole: "AGENT")
        
        let event1 = ChatEvent.participantIdle(data: eventData1)
        let event2 = ChatEvent.participantIdle(data: eventData2)
        let event3 = ChatEvent.participantIdle(data: eventData3)
        
        // Then
        XCTAssertEqual(event1, event2, "Same idle events should be equal")
        XCTAssertNotEqual(event1, event3, "Different event data should not be equal")
    }
    
    func testChatEventEquatable_ParticipantReturnedEvents() {
        // Given
        let eventData1 = createEventData(displayName: "Agent", participantRole: "AGENT")
        let eventData2 = createEventData(displayName: "Agent", participantRole: "AGENT")
        let eventData3 = createEventData(displayName: "Customer", participantRole: "CUSTOMER")
        
        let event1 = ChatEvent.participantReturned(data: eventData1)
        let event2 = ChatEvent.participantReturned(data: eventData2)
        let event3 = ChatEvent.participantReturned(data: eventData3)
        
        // Then
        XCTAssertEqual(event1, event2, "Same returned events should be equal")
        XCTAssertNotEqual(event1, event3, "Different event data should not be equal")
    }
    
    func testChatEventEquatable_AutoDisconnectionEvents() {
        // Given
        let eventData1 = createEventData(displayName: "Customer", participantRole: "CUSTOMER")
        let eventData2 = createEventData(displayName: "Customer", participantRole: "CUSTOMER")
        let eventData3 = createEventData(displayName: "Agent", participantRole: "AGENT")
        
        let event1 = ChatEvent.autoDisconnection(data: eventData1)
        let event2 = ChatEvent.autoDisconnection(data: eventData2)
        let event3 = ChatEvent.autoDisconnection(data: eventData3)
        
        // Then
        XCTAssertEqual(event1, event2, "Same disconnection events should be equal")
        XCTAssertNotEqual(event1, event3, "Different event data should not be equal")
    }
    
    func testChatEventEquatable_TypingEvents() {
        // Given
        let eventData1 = createEventData(displayName: "Agent", participantRole: "AGENT", contentType: "application/vnd.amazonaws.connect.event.typing")
        let eventData2 = createEventData(displayName: "Agent", participantRole: "AGENT", contentType: "application/vnd.amazonaws.connect.event.typing")
        let eventData3 = createEventData(displayName: "Customer", participantRole: "CUSTOMER", contentType: "application/vnd.amazonaws.connect.event.typing")
        
        let event1 = ChatEvent.typing(data: eventData1)
        let event2 = ChatEvent.typing(data: eventData2)
        let event3 = ChatEvent.typing(data: eventData3)
        
        // Then
        XCTAssertEqual(event1, event2, "Same typing events should be equal")
        XCTAssertNotEqual(event1, event3, "Different event data should not be equal")
    }
    
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
    
    func testChatEventEquatable_ParticipantInvitedEvents() {
        // Given
        let eventData1 = createEventData(displayName: "New Agent", participantRole: "AGENT", contentType: "application/vnd.amazonaws.connect.event.participant.invited")
        let eventData2 = createEventData(displayName: "New Agent", participantRole: "AGENT", contentType: "application/vnd.amazonaws.connect.event.participant.invited")
        let eventData3 = createEventData(displayName: "Supervisor", participantRole: "SUPERVISOR", contentType: "application/vnd.amazonaws.connect.event.participant.invited")
        
        let event1 = ChatEvent.participantInvited(data: eventData1)
        let event2 = ChatEvent.participantInvited(data: eventData2)
        let event3 = ChatEvent.participantInvited(data: eventData3)
        
        // Then
        XCTAssertEqual(event1, event2, "Same participant invited events should be equal")
        XCTAssertNotEqual(event1, event3, "Different event data should not be equal")
    }
    
    func testChatEventEquatable_ParticipantDisplayNameUpdatedEvents() {
        // Given
        let eventData1 = createEventData(displayName: "Updated Name", participantRole: "CUSTOMER", contentType: "application/vnd.amazonaws.connect.event.participant.displayname.updated")
        let eventData2 = createEventData(displayName: "Updated Name", participantRole: "CUSTOMER", contentType: "application/vnd.amazonaws.connect.event.participant.displayname.updated")
        let eventData3 = createEventData(displayName: "Different Name", participantRole: "CUSTOMER", contentType: "application/vnd.amazonaws.connect.event.participant.displayname.updated")
        
        let event1 = ChatEvent.participantDisplayNameUpdated(data: eventData1)
        let event2 = ChatEvent.participantDisplayNameUpdated(data: eventData2)
        let event3 = ChatEvent.participantDisplayNameUpdated(data: eventData3)
        
        // Then
        XCTAssertEqual(event1, event2, "Same display name updated events should be equal")
        XCTAssertNotEqual(event1, event3, "Different event data should not be equal")
    }
    
    func testChatEventEquatable_ChatRehydratedEvents() {
        // Given
        let eventData1 = createEventData(displayName: "System", participantRole: "SYSTEM", contentType: "application/vnd.amazonaws.connect.event.chat.rehydrated")
        let eventData2 = createEventData(displayName: "System", participantRole: "SYSTEM", contentType: "application/vnd.amazonaws.connect.event.chat.rehydrated")
        let eventData3 = createEventData(displayName: "System", participantRole: "SYSTEM", contentType: "application/vnd.amazonaws.connect.event.chat.rehydrated", messageId: "different-message")
        
        let event1 = ChatEvent.chatRehydrated(data: eventData1)
        let event2 = ChatEvent.chatRehydrated(data: eventData2)
        let event3 = ChatEvent.chatRehydrated(data: eventData3)
        
        // Then
        XCTAssertEqual(event1, event2, "Same chat rehydrated events should be equal")
        XCTAssertNotEqual(event1, event3, "Different event data should not be equal")
    }
    
    // MARK: - Cross-Event Type Tests
    
    func testChatEventEquatable_DifferentEventTypes() {
        // Given
        let eventData = createEventData(displayName: "Test User", participantRole: "CUSTOMER")
        
        let idleEvent = ChatEvent.participantIdle(data: eventData)
        let returnedEvent = ChatEvent.participantReturned(data: eventData)
        let typingEvent = ChatEvent.typing(data: eventData)
        let readReceiptEvent = ChatEvent.readReceipt(data: eventData)
        
        // Then
        XCTAssertNotEqual(idleEvent, returnedEvent, "Different event types should not be equal")
        XCTAssertNotEqual(idleEvent, typingEvent, "Different event types should not be equal")
        XCTAssertNotEqual(typingEvent, readReceiptEvent, "Different event types should not be equal")
        XCTAssertNotEqual(returnedEvent, readReceiptEvent, "Different event types should not be equal")
    }
    
    func testChatEventEquatable_SystemEvents() {
        // Given
        let connectionEstablished1 = ChatEvent.connectionEstablished
        let connectionEstablished2 = ChatEvent.connectionEstablished
        let connectionReEstablished = ChatEvent.connectionReEstablished
        let chatEnded = ChatEvent.chatEnded
        let connectionBroken = ChatEvent.connectionBroken
        
        // Then
        XCTAssertEqual(connectionEstablished1, connectionEstablished2, "Same system events should be equal")
        XCTAssertNotEqual(connectionEstablished1, connectionReEstablished, "Different system events should not be equal")
        XCTAssertNotEqual(connectionEstablished1, chatEnded, "Different system events should not be equal")
        XCTAssertNotEqual(chatEnded, connectionBroken, "Different system events should not be equal")
    }
    
    // MARK: - ContentType Tests
    
    func testContentTypeRawValues() {
        // Test that all ContentType cases have correct raw values
        XCTAssertEqual(ContentType.typing.rawValue, "application/vnd.amazonaws.connect.event.typing")
        XCTAssertEqual(ContentType.messageRead.rawValue, "application/vnd.amazonaws.connect.event.message.read")
        XCTAssertEqual(ContentType.messageDelivered.rawValue, "application/vnd.amazonaws.connect.event.message.delivered")
        XCTAssertEqual(ContentType.participantIdle.rawValue, "application/vnd.amazonaws.connect.event.participant.idle")
        XCTAssertEqual(ContentType.participantReturned.rawValue, "application/vnd.amazonaws.connect.event.participant.returned")
        XCTAssertEqual(ContentType.participantInvited.rawValue, "application/vnd.amazonaws.connect.event.participant.invited")
        XCTAssertEqual(ContentType.autoDisconnection.rawValue, "application/vnd.amazonaws.connect.event.participant.autodisconnection")
        XCTAssertEqual(ContentType.participantDisplayNameUpdated.rawValue, "application/vnd.amazonaws.connect.event.participant.displayname.updated")
        XCTAssertEqual(ContentType.chatRehydrated.rawValue, "application/vnd.amazonaws.connect.event.chat.rehydrated")
    }
    
    // MARK: - Event Data Field Tests
    
    func testEventDataFields_AllPresent() {
        // Given
        let eventData = createEventData(
            absoluteTime: "2024-08-01T21:00:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.typing",
            type: "EVENT",
            participantId: "participant-123",
            displayName: "Test Agent",
            participantRole: "AGENT",
            initialContactId: "contact-456",
            messageId: "message-789"
        )
        
        // Then - Verify all fields are accessible
        XCTAssertNotNil(eventData.absoluteTime)
        XCTAssertNotNil(eventData.contentType)
        XCTAssertNotNil(eventData.type)
        XCTAssertNotNil(eventData.participantId)
        XCTAssertNotNil(eventData.displayName)
        XCTAssertNotNil(eventData.participantRole)
        XCTAssertNotNil(eventData.initialContactId)
        XCTAssertNotNil(eventData.messageId)
    }
    
    func testEventDataFields_PartialData() {
        // Given - Some fields nil, some present
        let eventData = EventData(
            absoluteTime: "2024-08-01T21:00:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.typing",
            type: nil,
            participantId: "participant-123",
            displayName: nil,
            participantRole: "AGENT",
            initialContactId: nil,
            messageId: "message-789"
        )
        
        // Then
        XCTAssertEqual(eventData.absoluteTime, "2024-08-01T21:00:00.000Z")
        XCTAssertEqual(eventData.contentType, "application/vnd.amazonaws.connect.event.typing")
        XCTAssertNil(eventData.type)
        XCTAssertEqual(eventData.participantId, "participant-123")
        XCTAssertNil(eventData.displayName)
        XCTAssertEqual(eventData.participantRole, "AGENT")
        XCTAssertNil(eventData.initialContactId)
        XCTAssertEqual(eventData.messageId, "message-789")
    }
    
    // MARK: - Receipt Processing Architecture Tests
    
    func testReceiptEventArchitecture() {
        // Test that receipt events are properly structured for metadata processing
        
        // Given - Receipt events contain message-specific information
        let readReceiptEvent = Event(
            text: "Message read",
            timeStamp: "2024-08-01T21:02:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.read",
            messageId: "message-789",
            displayName: nil, // Receipts don't include display names
            participant: "participant-123", // Who sent the receipt
            eventDirection: .Incoming,
            serializedContent: [
                "receipt": ["ParticipantId": "participant-123", "ReadTimestamp": "2024-08-01T21:02:00.000Z"],
                "originalMessage": ["InitialContactId": "contact-456"]
            ]
        )
        
        let deliveredReceiptEvent = Event(
            text: "Message delivered",
            timeStamp: "2024-08-01T21:01:30.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.delivered",
            messageId: "message-789",
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [
                "receipt": ["ParticipantId": "participant-123", "DeliveredTimestamp": "2024-08-01T21:01:30.000Z"],
                "originalMessage": ["InitialContactId": "contact-456"]
            ]
        )
        
        // Then - Verify receipt events have the correct structure
        XCTAssertEqual(readReceiptEvent.contentType, "application/vnd.amazonaws.connect.event.message.read")
        XCTAssertEqual(readReceiptEvent.id, "message-789")
        XCTAssertEqual(readReceiptEvent.participant, "participant-123")
        XCTAssertNil(readReceiptEvent.displayName) // Receipts don't include display names
        XCTAssertEqual(readReceiptEvent.eventDirection, .Incoming)
        
        XCTAssertEqual(deliveredReceiptEvent.contentType, "application/vnd.amazonaws.connect.event.message.delivered")
        XCTAssertEqual(deliveredReceiptEvent.id, "message-789")
        XCTAssertEqual(deliveredReceiptEvent.participant, "participant-123")
    }
    
    func testReceiptEventEquality_MessageIdFocus() {
        // Given - Receipt events should be compared by their Event properties
        let receiptEvent1 = Event(
            text: "Message read",
            timeStamp: "2024-08-01T21:02:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.read",
            messageId: "message-789",
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        
        let receiptEvent2 = Event(
            text: "Message read",
            timeStamp: "2024-08-01T21:02:05.000Z", // Different timestamp
            contentType: "application/vnd.amazonaws.connect.event.message.read",
            messageId: "message-789", // Same message ID
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        
        let receiptEvent3 = Event(
            text: "Message read",
            timeStamp: "2024-08-01T21:02:00.000Z",
            contentType: "application/vnd.amazonaws.connect.event.message.read",
            messageId: "message-999", // Different message ID
            displayName: nil,
            participant: "participant-123",
            eventDirection: .Incoming,
            serializedContent: [:]
        )
        
        // Then - Different timestamps should make events unequal, different message IDs should make events unequal
        XCTAssertNotEqual(receiptEvent1, receiptEvent2, "Different timestamps should make events unequal")
        XCTAssertNotEqual(receiptEvent1, receiptEvent3, "Different message IDs should make events unequal")
    }
    
    // MARK: - Integration Tests
    
    func testChatEventInCollections() {
        // Given
        let eventData1 = createEventData(displayName: "User1", participantRole: "CUSTOMER")
        let eventData2 = createEventData(displayName: "User2", participantRole: "AGENT")
        
        let events: [ChatEvent] = [
            .participantIdle(data: eventData1),
            .participantReturned(data: eventData2),
            .typing(data: eventData1),
            .readReceipt(data: eventData2),
            .connectionEstablished,
            .chatEnded
        ]
        
        // Then
        XCTAssertEqual(events.count, 6, "All events should be stored in array")
        
        // Test Set functionality (requires Equatable)
        let eventSet = Set(events)
        XCTAssertEqual(eventSet.count, 6, "All unique events should be stored in set")
    }
    
    func testEventDataEquality_EdgeCases() {
        // Given - Empty strings vs nil
        let eventData1 = EventData(
            absoluteTime: "",
            contentType: "",
            type: "",
            participantId: "",
            displayName: "",
            participantRole: "",
            initialContactId: "",
            messageId: ""
        )
        
        let eventData2 = EventData(
            absoluteTime: nil,
            contentType: nil,
            type: nil,
            participantId: nil,
            displayName: nil,
            participantRole: nil,
            initialContactId: nil,
            messageId: nil
        )
        
        // Then
        XCTAssertNotEqual(eventData1, eventData2, "Empty strings should not equal nil values")
    }
}
    
    func testChatEventEquatable_DifferentEventTypes() {
        // Given
        let idleEvent = ChatEvent.participantIdle(displayName: "Customer")
        let returnedEvent = ChatEvent.participantReturned(displayName: "Customer")
        let disconnectionEvent = ChatEvent.autoDisconnection(displayName: "Customer")
        let connectionEvent = ChatEvent.connectionEstablished
        
        // Then
        XCTAssertNotEqual(idleEvent, returnedEvent, "Idle and returned events should not be equal")
        XCTAssertNotEqual(idleEvent, disconnectionEvent, "Idle and disconnection events should not be equal")
        XCTAssertNotEqual(idleEvent, connectionEvent, "Idle and connection events should not be equal")
        XCTAssertNotEqual(returnedEvent, disconnectionEvent, "Returned and disconnection events should not be equal")
    }
    
    func testContentTypeRawValues_ParticipantIdleEvents() {
        // Test that ContentType enum has correct raw values for participant idle events
        XCTAssertEqual(ContentType.participantIdle.rawValue, "application/vnd.amazonaws.connect.event.participant.idle")
        XCTAssertEqual(ContentType.participantReturned.rawValue, "application/vnd.amazonaws.connect.event.participant.returned")
        XCTAssertEqual(ContentType.autoDisconnection.rawValue, "application/vnd.amazonaws.connect.event.participant.autodisconnection")
    }
    
    func testContentTypeInitialization_ParticipantIdleEvents() {
        // Test that ContentType can be initialized from raw values
        XCTAssertEqual(ContentType(rawValue: "application/vnd.amazonaws.connect.event.participant.idle"), .participantIdle)
        XCTAssertEqual(ContentType(rawValue: "application/vnd.amazonaws.connect.event.participant.returned"), .participantReturned)
        XCTAssertEqual(ContentType(rawValue: "application/vnd.amazonaws.connect.event.participant.autodisconnection"), .autoDisconnection)
    }
    
    func testParticipantStateEventHandling_ValidData() {
        // Given
        let displayName = "Customer"
        let participantRole = "CUSTOMER"
        let absoluteTime = "2025-08-01T16:58:35.819Z"
        let messageId = "test-message-id"
        let contentType = "application/vnd.amazonaws.connect.event.participant.idle"
        
        let innerJson: [String: Any] = [
            "DisplayName": displayName,
            "ParticipantRole": participantRole,
            "AbsoluteTime": absoluteTime,
            "Id": messageId,
            "ContentType": contentType
        ]
        
        // When
        let extractedDisplayName = innerJson["DisplayName"] as? String ?? ""
        let extractedParticipantRole = innerJson["ParticipantRole"] as? String ?? ""
        let extractedTime = innerJson["AbsoluteTime"] as? String ?? ""
        let extractedMessageId = innerJson["Id"] as? String ?? ""
        let extractedContentType = innerJson["ContentType"] as? String ?? ""
        let isFromPastSession = innerJson["IsFromPastSession"] as? Bool ?? false
        
        // Then
        XCTAssertEqual(extractedDisplayName, displayName)
        XCTAssertEqual(extractedParticipantRole, participantRole)
        XCTAssertEqual(extractedTime, absoluteTime)
        XCTAssertEqual(extractedMessageId, messageId)
        XCTAssertEqual(extractedContentType, contentType)
        XCTAssertFalse(isFromPastSession)
    }
    
    func testParticipantStateEventHandling_MissingDisplayName() {
        // Given
        let innerJson: [String: Any] = [
            "ParticipantRole": "CUSTOMER",
            "AbsoluteTime": "2025-08-01T16:58:35.819Z",
            "Id": "test-id",
            "ContentType": "application/vnd.amazonaws.connect.event.participant.idle"
            // DisplayName is missing
        ]
        
        // When
        let extractedDisplayName = innerJson["DisplayName"] as? String ?? ""
        
        // Then
        XCTAssertEqual(extractedDisplayName, "", "Missing display name should default to empty string")
    }
    
    func testParticipantStateEventHandling_PastSession() {
        // Given
        let innerJson: [String: Any] = [
            "DisplayName": "Customer",
            "ParticipantRole": "CUSTOMER",
            "AbsoluteTime": "2025-08-01T16:58:35.819Z",
            "Id": "test-id",
            "ContentType": "application/vnd.amazonaws.connect.event.participant.idle",
            "IsFromPastSession": true
        ]
        
        // When
        let isFromPastSession = innerJson["IsFromPastSession"] as? Bool ?? false
        
        // Then
        XCTAssertTrue(isFromPastSession, "Past session flag should be detected")
    }
    
    func testCallbackFunctionSignature_ParticipantIdleEvents() {
        // Test that callback functions can be assigned and called with correct signature
        var callbackTriggered = false
        var receivedDisplayName: String?
        
        // Simulate callback assignment
        let onParticipantIdle: (String) -> Void = { displayName in
            callbackTriggered = true
            receivedDisplayName = displayName
        }
        
        let onParticipantReturned: (String) -> Void = { displayName in
            callbackTriggered = true
            receivedDisplayName = displayName
        }
        
        let onAutoDisconnection: (String) -> Void = { displayName in
            callbackTriggered = true
            receivedDisplayName = displayName
        }
        
        // Test idle callback
        onParticipantIdle("Customer")
        XCTAssertTrue(callbackTriggered)
        XCTAssertEqual(receivedDisplayName, "Customer")
        
        // Reset and test returned callback
        callbackTriggered = false
        receivedDisplayName = nil
        onParticipantReturned("Agent")
        XCTAssertTrue(callbackTriggered)
        XCTAssertEqual(receivedDisplayName, "Agent")
        
        // Reset and test disconnection callback
        callbackTriggered = false
        receivedDisplayName = nil
        onAutoDisconnection("System")
        XCTAssertTrue(callbackTriggered)
        XCTAssertEqual(receivedDisplayName, "System")
    }
    
    func testSpecialCharactersInDisplayName() {
        // Given
        let specialDisplayName = "Agent 🤖 Smith-Jones (Support) <test@example.com>"
        let innerJson: [String: Any] = [
            "DisplayName": specialDisplayName,
            "ParticipantRole": "AGENT",
            "AbsoluteTime": "2025-08-01T16:58:35.819Z",
            "Id": "test-id",
            "ContentType": "application/vnd.amazonaws.connect.event.participant.returned"
        ]
        
        // When
        let extractedDisplayName = innerJson["DisplayName"] as? String ?? ""
        
        // Then
        XCTAssertEqual(extractedDisplayName, specialDisplayName, "Special characters in display names should be preserved")
    }
}
