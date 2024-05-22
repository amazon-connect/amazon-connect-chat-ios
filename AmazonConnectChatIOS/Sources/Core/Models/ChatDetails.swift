// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

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

public struct ChatSessionOptions {
    var region: AWSRegionType = Constants.DEFAULT_REGION
}
