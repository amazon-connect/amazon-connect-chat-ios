// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant

struct CommonUtils {
    
    func convertParticipantRoleToString(_ roleValue: Int) -> String {
        switch roleValue {
        case AWSConnectParticipantParticipantRole.agent.rawValue:
            return Constants.AGENT
        case AWSConnectParticipantParticipantRole.customer.rawValue:
            return Constants.CUSTOMER
        case AWSConnectParticipantParticipantRole.system.rawValue:
            return Constants.SYSTEM
        default:
            return Constants.UNKNOWN
        }
    }

    func convertParticipantTypeToString(_ roleValue: Int) -> String {
        switch roleValue {
        case AWSConnectParticipantChatItemType.message.rawValue:
            return Constants.MESSAGE
        case AWSConnectParticipantChatItemType.event.rawValue:
            return Constants.EVENT
        case AWSConnectParticipantChatItemType.attachment.rawValue:
            return Constants.ATTACHMENT
        default:
            return Constants.UNKNOWN
        }
    }
    
    func convertMessageMetadataToDict(_ messageMetadata: AWSConnectParticipantMessageMetadata?) -> [String: Any] {
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
        return "2.0.6"
    }
}
