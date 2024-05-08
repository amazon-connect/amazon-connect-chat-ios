//
//  GlobalConfig.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation
import AWSCore


public struct GlobalConfig {
    public var region: AWSRegionType
    public var features: Features
    public var customMessages: CustomMessages


    public static var defaultRegion: AWSRegionType {
        return Constants.DEFAULT_REGION
    }

    // Initializes a new global configuration with optional custom settings or defaults
    public init(region: AWSRegionType = defaultRegion, features: Features = .defaultFeatures, customMessages: CustomMessages = .defaultMessages) {
        self.region = region
        self.features = features
        self.customMessages = customMessages
    }
}

public struct CustomMessages {
    public var chatEnded: String
    public var participantJoined: String
    public var participantLeft: String

    public static var defaultMessages: CustomMessages {
        return CustomMessages(
            chatEnded: "The chat has ended.",
            participantJoined: "%@ has joined the chat.",
            participantLeft: "%@ has left the chat."
        )
    }

    public init(chatEnded: String, participantJoined: String, participantLeft: String) {
        self.chatEnded = chatEnded
        self.participantJoined = participantJoined
        self.participantLeft = participantLeft
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
    public var throttleTime: Int
    
    // Provides default MessageReceipts configuration
    public static var defaultReceipts: MessageReceipts {
        return MessageReceipts(shouldSendMessageReceipts: true, throttleTime: Constants.MESSAGE_RECEIPT_THROTTLE_TIME)
    }
    
    public init(shouldSendMessageReceipts: Bool, throttleTime: Int) {
        self.shouldSendMessageReceipts = shouldSendMessageReceipts
        self.throttleTime = throttleTime
    }
    
}
