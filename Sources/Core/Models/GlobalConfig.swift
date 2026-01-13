// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSCore


public struct GlobalConfig {
    public var region: AWSRegionType
    public var features: Features
    public var disableCsm: Bool
    public var customAWSClient: AWSClientProtocol?
    public var customWebSocketURLProvider: ((String) -> String)?

    public static var defaultRegion: AWSRegionType {
        return Constants.DEFAULT_REGION
    }

    // Initializes a new global configuration with optional custom settings or defaults
    public init(region: AWSRegionType = defaultRegion, features: Features = .defaultFeatures, disableCsm: Bool = false, customAWSClient: AWSClientProtocol? = nil, customWebSocketURLProvider: ((String) -> String)? = nil) {
        self.region = region
        self.features = features
        self.disableCsm = disableCsm
        self.customAWSClient = customAWSClient
        self.customWebSocketURLProvider = customWebSocketURLProvider
    }
}


public struct Features {
    public var messageReceipts: MessageReceipts

    // Provides default Features configuration
    public static var defaultFeatures: Features {
        return Features(messageReceipts: .defaultReceipts)
    }

    public init(messageReceipts: MessageReceipts = .defaultReceipts) {
        self.messageReceipts = messageReceipts
    }
}


public struct MessageReceipts {
    public var shouldSendMessageReceipts: Bool
    public var throttleTime: Double
    
    // Provides default MessageReceipts configuration
    public static var defaultReceipts: MessageReceipts {
        return MessageReceipts(shouldSendMessageReceipts: true, throttleTime: Constants.MESSAGE_RECEIPT_THROTTLE_TIME)
    }
    
    public init(shouldSendMessageReceipts: Bool, throttleTime: Double) {
        self.shouldSendMessageReceipts = shouldSendMessageReceipts
        self.throttleTime = throttleTime
    }
    
}
