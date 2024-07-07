// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public enum MessageStatus : String {
    case Delivered = "Delivered"
    case Read = "Read"
    case Sending = "Sending"
    case Failed = "Failed to send"
    case Sent = "Sent"
    case Unknown = ""     // Leaving it empty as in case of unknown as it would not render anythin on UI if customer is relying on Enum values
}

public protocol MetadataProtocol: TranscriptItemProtocol {
    var status: MessageStatus? { get set }
    var eventDirection: MessageDirection? { get set }
//    func copy() -> any MetadataProtocol
}

public class Metadata: TranscriptItem, MetadataProtocol {
    @Published public var status: MessageStatus?
    @Published public var eventDirection: MessageDirection?
    
    init(status: MessageStatus? = nil, messageId: String? = nil, timeStamp: String, contentType: String, eventDirection: MessageDirection? = .Common, serializedContent: [String: Any]) {
        self.status = status
        self.eventDirection = eventDirection
        super.init(timeStamp: timeStamp, contentType: contentType, id: messageId, serializedContent: serializedContent)
    }
    
//    public func copy() -> any MetadataProtocol {
//        return Metadata(status: self.status, messageId: self.id, timeStamp: self.timeStamp, contentType: self.contentType, eventDirection: self.eventDirection, serializedContent: self.serializedContent ?? [:])
//    }
}
