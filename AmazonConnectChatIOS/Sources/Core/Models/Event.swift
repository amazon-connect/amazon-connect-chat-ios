// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

protocol EventProtocol: TranscriptItemProtocol {
    var participant: String? { get set }
    var text: String? { get set }
    var eventDirection: MessageDirection? { get set }
}

public class Event: TranscriptItem, EventProtocol {
    public var participant: String?
    public var text: String?
    public var eventDirection: MessageDirection?
    
    init(text: String? = nil, timeStamp: String, contentType: String, participant: String? = nil, eventDirection: MessageDirection? = .Common, serializedContent: [String: Any]) {
        self.participant = participant
        self.text = text
        self.eventDirection = eventDirection
        super.init(timeStamp: timeStamp, contentType: contentType, serializedContent: serializedContent)
    }
}
