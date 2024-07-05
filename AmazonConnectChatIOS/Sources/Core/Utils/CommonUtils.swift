// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import AWSConnectParticipant

struct CommonUtils {

    func formatTime(_ timeStamp: String) -> String? {
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Use a POSIX locale for fixed format parsing
            
            // Attempt to convert UTC time to Date
            guard let utcDate = dateFormatter.date(from: timeStamp) else {
                return timeStamp // Return the original timestamp as a fallback
            }
            
            // Set the date formatter's timezone to the device's local timezone and format for display
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.dateFormat = "HH:mm"
            
            // Convert to local time or fallback to UTC time string
            let localTime = dateFormatter.string(from: utcDate)
//            return localTime.isEmpty ? timeStamp : localTime
        return timeStamp
    }
    
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
