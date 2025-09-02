// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSCore

public struct Constants {
    static let AWSConnectParticipantKey = "AWSConnectParticipant"
    static let ACPSRequestTypes = ["WEBSOCKET", "CONNECTION_CREDENTIALS"]
    static let AGENT = "AGENT"
    
    // TODO: Remove this print statement - added to test linting failure
    static func testPrint() {
        print("This should fail the linting check")
    }
    static let CUSTOMER = "CUSTOMER"
    static let SYSTEM = "SYSTEM"
    static let UNKNOWN = "UNKNOWN"
    static let MESSAGE = "MESSAGE"
    static let ATTACHMENT = "ATTACHMENT"
    static let EVENT = "EVENT"
    static let MESSAGE_RECEIPT_THROTTLE_TIME = 5.0
    static let DEFAULT_REGION : AWSRegionType  = .USWest2
    public static let QUICK_REPLY = "QuickReply"
    public static let LIST_PICKER = "ListPicker"
    public static let PANEL = "Panel"
    public static let TIME_PICKER = "TimePicker"
    public static let CAROUSEL = "Carousel"
    
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
