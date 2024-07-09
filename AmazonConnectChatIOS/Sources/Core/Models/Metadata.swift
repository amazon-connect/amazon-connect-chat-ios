// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public enum MessageStatus {
    case Delivered
    case Read
    case Sending
    case Failed
    case Sent
    case Unknown // Leaving it empty as in case of unknown as it would not render anythin on UI if customer is relying on Enum values
}

public protocol MetadataProtocol: TranscriptItemProtocol {
    var status: MessageStatus? { get set }
    var eventDirection: MessageDirection? { get set }
}

public class Metadata: TranscriptItem, MetadataProtocol {
    @Published public var status: MessageStatus?
    @Published public var eventDirection: MessageDirection?
    
    init(status: MessageStatus? = nil, messageId: String? = nil, timeStamp: String, contentType: String, eventDirection: MessageDirection? = .Common, serializedContent: [String: Any]) {
        self.status = status
        self.eventDirection = eventDirection
        super.init(timeStamp: timeStamp, contentType: contentType, id: messageId, serializedContent: serializedContent)
    }
    
}
