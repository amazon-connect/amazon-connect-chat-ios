//
//  Constants.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/5/24.
//

import Foundation
import AWSCore

struct Constants {
    static let AWSConnectParticipantKey = "AWSConnectParticipant"
    static let ACPSRequestTypes = ["WEBSOCKET", "CONNECTION_CREDENTIALS"]
    static let AGENT = "AGENT"
    static let CUSTOMER = "CUSTOMER"
    static let SYSTEM = "SYSTEM"
    static let UNKNOWN = "UNKNOWN"
    static let MESSAGE = "MESSAGE"
    static let EVENT = "EVENT"
    static let MESSAGE_RECEIPT_THROTTLE_TIME = 5000
    static let DEFAULT_REGION : AWSRegionType  = .USWest2
    static let QUICK_REPLY = "QuickReply"
    static let LIST_PICKER = "ListPicker"
    
    // For future reference
    struct Error {
        static func connectionCreated(reason: String) -> String {
            return "Failed to create connection: \(reason)."
        }
        static func connectionFailed(reason: String) -> String {
            return "Failed to create connection: \(reason)."
        }
    }
    
}
