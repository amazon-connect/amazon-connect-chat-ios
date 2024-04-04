//
//  GlobalConfig.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation
import AWSCore

struct GlobalConfig {
    var region: AWSRegionType = .USEast1
    var features: Features = Features()
}

struct Features {
    var messageReceipts: MessageReceipts = MessageReceipts()
}

struct MessageReceipts {
    var shouldSendMessageReceipts: Bool = true
    var throttleTime: Int = 5000
}
