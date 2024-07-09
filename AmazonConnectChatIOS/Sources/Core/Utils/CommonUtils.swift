// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

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

}
