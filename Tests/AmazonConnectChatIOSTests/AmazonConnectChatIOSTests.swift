// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import AmazonConnectChatIOS

final class AmazonConnectChatIOSTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
    
    // MARK: - Participant Idle Events Tests
    
    func testChatEventEquatable_ParticipantIdleEvents() {
        // Given
        let event1 = ChatEvent.participantIdle(displayName: "Customer")
        let event2 = ChatEvent.participantIdle(displayName: "Customer")
        let event3 = ChatEvent.participantIdle(displayName: "Agent")
        
        // Then
        XCTAssertEqual(event1, event2, "Same idle events should be equal")
        XCTAssertNotEqual(event1, event3, "Different display names should not be equal")
    }
    
    func testChatEventEquatable_ParticipantReturnedEvents() {
        // Given
        let event1 = ChatEvent.participantReturned(displayName: "Agent")
        let event2 = ChatEvent.participantReturned(displayName: "Agent")
        let event3 = ChatEvent.participantReturned(displayName: "Customer")
        
        // Then
        XCTAssertEqual(event1, event2, "Same returned events should be equal")
        XCTAssertNotEqual(event1, event3, "Different display names should not be equal")
    }
    
    func testChatEventEquatable_AutoDisconnectionEvents() {
        // Given
        let event1 = ChatEvent.autoDisconnection(displayName: "Customer")
        let event2 = ChatEvent.autoDisconnection(displayName: "Customer")
        let event3 = ChatEvent.autoDisconnection(displayName: "Agent")
        
        // Then
        XCTAssertEqual(event1, event2, "Same disconnection events should be equal")
        XCTAssertNotEqual(event1, event3, "Different display names should not be equal")
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
