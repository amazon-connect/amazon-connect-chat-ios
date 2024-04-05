//
//  ChatDetails.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation
import AWSCore

struct ChatDetails {
    var contactId: String
    var participantId: String
    var participantToken: String
}

struct ChatSessionOptions {
    var region: AWSRegionType = Constants.DEFAULT_REGION
}
