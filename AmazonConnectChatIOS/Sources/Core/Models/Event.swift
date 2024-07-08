// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public protocol EventProtocol: TranscriptItemProtocol {
    var participant: String? { get set }
    var text: String? { get set }
    var displayName: String? { get set }
    var eventDirection: MessageDirection? { get set }
//    func copy() -> any EventProtocol
}

public class Event: TranscriptItem, EventProtocol {
    public var participant: String?
    public var text: String?
    public var displayName: String?
    public var eventDirection: MessageDirection?
    
    public init(text: String? = nil, timeStamp: String, contentType: String, messageId: String, displayName: String? = nil, participant: String? = nil, eventDirection: MessageDirection? = .Common, serializedContent: [String: Any]) {
        self.participant = participant
        self.text = text
        self.displayName = displayName
        self.eventDirection = eventDirection
        super.init(timeStamp: timeStamp, contentType: contentType, id: messageId, serializedContent: serializedContent)
    }
    
//    public func copy() -> any EventProtocol {
//        return Event(text: self.text, timeStamp: self.timeStamp, contentType: self.contentType, messageId: self.id, displayName: self.displayName, participant: self.participant, eventDirection: self.eventDirection, serializedContent: self.serializedContent ?? [:])
//    }
}
