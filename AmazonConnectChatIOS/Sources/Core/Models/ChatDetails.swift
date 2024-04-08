//
//  ChatDetails.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation
import AWSCore

public struct ChatDetails {
    var contactId: String
    var participantId: String
    var participantToken: String
    
    public init(contactId: String, participantId: String, participantToken: String) {
        self.contactId = contactId
        self.participantId = participantId
        self.participantToken = participantToken
    }
}

struct ChatSessionOptions {
    var region: AWSRegionType = Constants.DEFAULT_REGION
}
