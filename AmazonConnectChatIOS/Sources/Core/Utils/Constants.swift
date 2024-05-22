// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import AWSCore

public struct Constants {
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
    public static let QUICK_REPLY = "QuickReply"
    public static let LIST_PICKER = "ListPicker"
    
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
