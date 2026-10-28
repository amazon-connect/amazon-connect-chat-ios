// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant

public struct Constants {
    static let ACPSRequestTypes: [ConnectParticipantClientTypes.ConnectionType] = [.websocket, .connectionCredentials]
    static let AGENT = "AGENT"
    static let CUSTOMER = "CUSTOMER"
    static let SYSTEM = "SYSTEM"
    static let SUPERVISOR = "SUPERVISOR"
    static let CUSTOM_BOT = "CUSTOM_BOT"
    static let UNKNOWN = "UNKNOWN"
    static let MESSAGE = "MESSAGE"
    static let ATTACHMENT = "ATTACHMENT"
    static let EVENT = "EVENT"
    static let MESSAGE_RECEIPT_THROTTLE_TIME = 5.0
    static let DEFAULT_REGION: Region = .usWest2

    /// Identifies this SDK in the `User-Agent` header.
    ///
    /// The AWS SDK for Swift's supported extension point renders this as `app/<appID>` and
    /// sanitizes unsupported characters. This is the 3.0 equivalent of the legacy
    /// `AmazonConnect-Mobile Chat-iOS SDK/<version>` product token.
    static func userAgentAppID() -> String {
        "AmazonConnect-Mobile-Chat-iOS-SDK-\(CommonUtils.getLibraryVersion())"
    }

    /// The exact 2.x `addUserAgentProductToken` value, appended to the `User-Agent` header by
    /// `UserAgentProductTokenHTTPClient` so service-side attribution keyed on the legacy token
    /// keeps working across the 3.0 migration.
    static func userAgentProductToken() -> String {
        "AmazonConnect-Mobile Chat-iOS SDK/\(CommonUtils.getLibraryVersion())"
    }

    public static let QUICK_REPLY = "QuickReply"
    public static let LIST_PICKER = "ListPicker"
    public static let PANEL = "Panel"
    public static let TIME_PICKER = "TimePicker"
    public static let CAROUSEL = "Carousel"
    public static let VIEW_RESOURCE = "ViewResource"

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
