//
//  TranscriptItemUtils.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 7/9/24.
//

import Foundation
struct TranscriptItemUtils {
    
    static func createDummyEndedEvent() -> Event {
        let currentDate = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let currentTime = formatter.string(from: currentDate)
        let isoTime = isoFormatter.string(from: currentDate)
        
        let serializedContent = [
            "content": "{\"AbsoluteTime\":\"\(isoTime)\",\"ContentType\":\"application/vnd.amazonaws.connect.event.chat.ended\",\"Id\":\"chat-ended-event\",\"Type\":\"EVENT\",\"InitialContactId\":\"chat-ended-event-id\"}",
            "topic": "aws/chat",
            "contentType": "application/json"
        ]
        
        return Event(text: nil, timeStamp: currentTime, contentType: ContentType.ended.rawValue, messageId: "chat-ended-event", serializedContent: serializedContent)
    }
    
    static func createDummyMessage(content: String, contentType: String, status: MessageStatus, attachmentId: String? = nil, displayName: String) -> Message {
        return Message(
            participant: "CUSTOMER",
            text: content,
            contentType: contentType,
            messageDirection: .Outgoing,
            timeStamp: "",
            attachmentId: attachmentId,
            messageId: UUID().uuidString,
            displayName: displayName,
            serializedContent: [:],
            metadata: Metadata(status:status, timeStamp: "", contentType: contentType, eventDirection: MessageDirection.Outgoing, serializedContent: [:])
        )
    }

}
