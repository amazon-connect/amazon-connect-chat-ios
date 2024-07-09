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
    public var displayName: String?
    public var eventDirection: MessageDirection?
    
    init(text: String? = nil, timeStamp: String, contentType: String, messageId: String, displayName: String? = nil, participant: String? = nil, eventDirection: MessageDirection? = .Common, serializedContent: [String: Any]) {
        self.participant = participant
        self.text = text
        self.displayName = displayName
        self.eventDirection = eventDirection
        super.init(timeStamp: timeStamp, contentType: contentType, id: messageId, serializedContent: serializedContent)
    }
}

class DummyEndedEvent: Event {
    init() {
        let currentDate = Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let currentTime = formatter.string(from: currentDate)
        
        let isoTime = isoFormatter.string(from: currentDate)
        
        let serizliedContent = [
            "content": "{\"AbsoluteTime\":\"\(isoTime)\",\"ContentType\":\"application/vnd.amazonaws.connect.event.chat.ended\",\"Id\":\"chat-ended-event\",\"Type\":\"EVENT\",\"InitialContactId\":\"chat-ended-event-id\"}\"]",
            "topic": "aws/chat",
            "contentType": "application/json"
        ];
        
        super.init(text: nil, timeStamp: currentTime, contentType: ContentType.ended.rawValue, messageId: "chat-ended-event", serializedContent: serizliedContent)
    }
    
}
