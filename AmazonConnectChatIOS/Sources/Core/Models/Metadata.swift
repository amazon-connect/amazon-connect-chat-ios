// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public enum MessageStatus : String {
    case Delivered = "Delivered"
    case Read = "Read"
    case Unknown = ""     // Leaving it empty as in case of unknown as it would not render anythin on UI if customer is relying on Enum values
}

protocol MetadataProtocol: TranscriptItemProtocol {
    var status: MessageStatus? { get set }
    var messageId: String? { get set }
    var eventDirection: MessageDirection? { get set }
}

public class Metadata: TranscriptItem, MetadataProtocol {
    public var status: MessageStatus?
    public var messageId: String?
    public var eventDirection: MessageDirection?
    
    init(status: MessageStatus? = nil, messageId: String? = nil, timeStamp: String, contentType: String, eventDirection: MessageDirection? = .Common) {
        self.status = status
        self.messageId = messageId
        self.eventDirection = eventDirection
        super.init(timeStamp: timeStamp, contentType: contentType)
    }
}
