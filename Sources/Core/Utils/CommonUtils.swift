// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant

struct CommonUtils {

    /// Maps a participant role onto the string used in serialized transcript content.
    /// Mapped explicitly rather than via `rawValue` so unrecognised roles resolve to `UNKNOWN`.
    func convertParticipantRoleToString(_ role: ConnectParticipantClientTypes.ParticipantRole?) -> String {
        switch role {
        case .some(.agent):
            return Constants.AGENT
        case .some(.customer):
            return Constants.CUSTOMER
        case .some(.system):
            return Constants.SYSTEM
        case .some(.supervisor):
            return Constants.SUPERVISOR
        case .some(.customBot):
            return Constants.CUSTOM_BOT
        default:
            return Constants.UNKNOWN
        }
    }

    /// Maps a chat item type onto the string used in serialized transcript content.
    ///
    /// Do not forward `rawValue` here. This string is parsed back by
    /// `WebsocketManager.processJsonContentAndGetItem` via `WebSocketMessageType(rawValue:)`.
    /// Transcript API item types other than MESSAGE / EVENT / ATTACHMENT are not supported by that
    /// parser and must follow the existing UNKNOWN fallback.
    func convertParticipantTypeToString(_ type: ConnectParticipantClientTypes.ChatItemType?) -> String {
        switch type {
        case .some(.message):
            return Constants.MESSAGE
        case .some(.event):
            return Constants.EVENT
        case .some(.attachment):
            return Constants.ATTACHMENT
        default:
            return Constants.UNKNOWN
        }
    }

    func convertMessageMetadataToDict(_ messageMetadata: ConnectParticipantClientTypes.MessageMetadata?) -> [String: Any] {
        guard let messageId = messageMetadata?.messageId else {
            return [:]
        }

        return [
            "MessageId": messageId,
            "Receipts": messageMetadata?.receipts?.compactMap { receipt in
                return [
                    "ReadTimestamp": receipt.readTimestamp ?? nil,
                    "DeliveredTimestamp": receipt.deliveredTimestamp ?? nil,
                    "RecipientParticipantId": receipt.recipientParticipantId ?? nil
                ]
            } ?? []
        ]
    }

    static func getCurrentISOTime() -> String {
        let currentDate = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
        return isoFormatter.string(from: currentDate)
    }

    static func getLibraryVersion() -> String {
        return "3.0.0"
    }
}
