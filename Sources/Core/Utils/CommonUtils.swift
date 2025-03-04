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
    
    static func getCurrentISOTime() -> String {
        let currentDate = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
        return isoFormatter.string(from: currentDate)
    }
    
    static func getLibraryVersion() -> String {
        // Update manually per release
        return "1.0.6"
    }
}
