//
//  Metadata.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 5/7/24.
//

import Foundation

protocol MetadataProtocol: TranscriptItemProtocol {
    var status: String? { get set }
    var messageId: String? { get set }
    var eventDirection: MessageDirection? { get set }
}

public class Metadata: TranscriptItem, MetadataProtocol {
    public var status: String?
    public var messageId: String?
    public var eventDirection: MessageDirection?
    
    init(status: String? = nil, messageId: String? = nil, timeStamp: String, contentType: String, eventDirection: MessageDirection? = .Common) {
        self.status = status
        self.messageId = messageId
        self.eventDirection = eventDirection
        super.init(timeStamp: timeStamp, contentType: contentType)
    }
}
