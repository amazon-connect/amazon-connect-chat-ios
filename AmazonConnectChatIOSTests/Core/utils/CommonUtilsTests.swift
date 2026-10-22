// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

// Covers the enum-to-string mapping used when serializing transcript items. `MockWebsocketManager`
// substitutes its own `formatAndProcessTranscriptItems`, so nothing else exercises this code.
class CommonUtilsTests: XCTestCase {

    let commonUtils = CommonUtils()

    // MARK: - Participant role

    func testConvertParticipantRoleToString_MapsKnownRoles() {
        XCTAssertEqual(commonUtils.convertParticipantRoleToString(.agent), Constants.AGENT)
        XCTAssertEqual(commonUtils.convertParticipantRoleToString(.customer), Constants.CUSTOMER)
        XCTAssertEqual(commonUtils.convertParticipantRoleToString(.system), Constants.SYSTEM)
        XCTAssertEqual(commonUtils.convertParticipantRoleToString(.supervisor), Constants.SUPERVISOR)
        XCTAssertEqual(commonUtils.convertParticipantRoleToString(.customBot), Constants.CUSTOM_BOT)
    }

    func testConvertParticipantRoleToString_NilIsUnknown() {
        XCTAssertEqual(commonUtils.convertParticipantRoleToString(nil), Constants.UNKNOWN)
    }

    // A role the service adds after this release must degrade to UNKNOWN
    func testConvertParticipantRoleToString_UnrecognisedRoleIsUnknown() {
        XCTAssertEqual(commonUtils.convertParticipantRoleToString(.sdkUnknown("DROID")), Constants.UNKNOWN)
    }

    // MARK: - Chat item type

    func testConvertParticipantTypeToString_MapsKnownTypes() {
        XCTAssertEqual(commonUtils.convertParticipantTypeToString(.message), Constants.MESSAGE)
        XCTAssertEqual(commonUtils.convertParticipantTypeToString(.event), Constants.EVENT)
        XCTAssertEqual(commonUtils.convertParticipantTypeToString(.attachment), Constants.ATTACHMENT)
    }

    func testConvertParticipantTypeToString_NilIsUnknown() {
        XCTAssertEqual(commonUtils.convertParticipantTypeToString(nil), Constants.UNKNOWN)
    }

    // REGRESSION GUARD: do not simplify `convertParticipantTypeToString` to return `rawValue`.
    // Transcript API item types other than MESSAGE / EVENT / ATTACHMENT are not supported by the
    // existing WebSocket parser.
    func testConvertParticipantTypeToString_OtherTypesAreUnknownNotRawValue() {
        let othersThatMustNotLeakRawValues: [ConnectParticipantClientTypes.ChatItemType] = [
            .typing, .chatEnded, .connectionAck, .messageDelivered, .messageRead,
            .participantJoined, .participantLeft, .transferFailed, .transferSucceeded
        ]

        for type in othersThatMustNotLeakRawValues {
            XCTAssertEqual(
                commonUtils.convertParticipantTypeToString(type),
                Constants.UNKNOWN,
                "\(type.rawValue) must map to UNKNOWN; returning its rawValue would break WebSocketMessageType parsing"
            )
            XCTAssertNil(
                WebSocketMessageType(rawValue: type.rawValue),
                "Sanity check: \(type.rawValue) is not a WebSocketMessageType, which is why it must not be forwarded"
            )
        }
    }

    func testMappedTypeStringsAreParseableByWebSocketMessageType() {
        XCTAssertEqual(WebSocketMessageType(rawValue: Constants.MESSAGE), .message)
        XCTAssertEqual(WebSocketMessageType(rawValue: Constants.EVENT), .event)
        XCTAssertEqual(WebSocketMessageType(rawValue: Constants.ATTACHMENT), .attachment)
    }

    // MARK: - Message metadata

    func testConvertMessageMetadataToDict_EmptyWhenNoMessageId() {
        let metadata = ConnectParticipantClientTypes.MessageMetadata()
        XCTAssertTrue(commonUtils.convertMessageMetadataToDict(metadata).isEmpty)
        XCTAssertTrue(commonUtils.convertMessageMetadataToDict(nil).isEmpty)
    }

    func testConvertMessageMetadataToDict_IncludesMessageIdAndReceipts() {
        let metadata = ConnectParticipantClientTypes.MessageMetadata(
            messageId: "message-1",
            receipts: [
                ConnectParticipantClientTypes.Receipt(
                    deliveredTimestamp: "2026-01-01T00:00:00.000Z",
                    readTimestamp: "2026-01-01T00:00:01.000Z",
                    recipientParticipantId: "participant-1"
                )
            ]
        )

        let dict = commonUtils.convertMessageMetadataToDict(metadata)

        XCTAssertEqual(dict["MessageId"] as? String, "message-1")
        let receipts = dict["Receipts"] as? [[String: Any]]
        XCTAssertEqual(receipts?.count, 1)
        XCTAssertEqual(receipts?.first?["RecipientParticipantId"] as? String, "participant-1")
        XCTAssertEqual(receipts?.first?["ReadTimestamp"] as? String, "2026-01-01T00:00:01.000Z")
        XCTAssertEqual(receipts?.first?["DeliveredTimestamp"] as? String, "2026-01-01T00:00:00.000Z")
    }

    // MARK: - Scan direction / sort order bridging

    func testScanDirectionBridging() {
        XCTAssertEqual(ScanDirection.forward.sdkValue, .forward)
        XCTAssertEqual(ScanDirection.backward.sdkValue, .backward)
        XCTAssertEqual(ScanDirection(sdkValue: .forward), .forward)
        XCTAssertEqual(ScanDirection(sdkValue: .backward), .backward)
        XCTAssertNil(ScanDirection(sdkValue: nil))
        XCTAssertNil(ScanDirection(sdkValue: .sdkUnknown("SIDEWAYS")))
    }

    func testSortKeyBridging() {
        XCTAssertEqual(SortKey.ascending.sdkValue, .ascending)
        XCTAssertEqual(SortKey.descending.sdkValue, .descending)
        XCTAssertEqual(SortKey(sdkValue: .ascending), .ascending)
        XCTAssertEqual(SortKey(sdkValue: .descending), .descending)
        XCTAssertNil(SortKey(sdkValue: nil))
        XCTAssertNil(SortKey(sdkValue: .sdkUnknown("RANDOM")))
    }

    func testScanDirectionAndSortOrderWireValues() {
        XCTAssertEqual(ScanDirection.forward.sdkValue.rawValue, "FORWARD")
        XCTAssertEqual(ScanDirection.backward.sdkValue.rawValue, "BACKWARD")
        XCTAssertEqual(SortKey.ascending.sdkValue.rawValue, "ASCENDING")
        XCTAssertEqual(SortKey.descending.sdkValue.rawValue, "DESCENDING")
    }

    // MARK: - Connection types

    // Wire values must be unchanged now that this is `[ConnectionType]` rather than `[String]`
    func testACPSRequestTypesWireValues() {
        XCTAssertEqual(Constants.ACPSRequestTypes.map(\.rawValue), ["WEBSOCKET", "CONNECTION_CREDENTIALS"])
    }

    // MARK: - Version / user agent

    func testUserAgentAppIDCarriesLibraryVersion() {
        let appID = Constants.userAgentAppID()
        XCTAssertEqual(appID, "AmazonConnect-Mobile-Chat-iOS-SDK-\(CommonUtils.getLibraryVersion())")
        // Must stay a single User-Agent-safe token; the AWS SDK renders it as `app/<appID>`.
        XCTAssertFalse(appID.contains(" "))
        XCTAssertFalse(appID.contains("/"))
    }
}
