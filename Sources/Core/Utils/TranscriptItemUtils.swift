// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation

struct TranscriptItemUtils {
    
    static func createDummyEndedEvent() -> Event {
        let isoTime = CommonUtils.getCurrentISOTime()
        
        let serializedContent = [
            "content": "{\"AbsoluteTime\":\"\(isoTime)\",\"ContentType\":\"application/vnd.amazonaws.connect.event.chat.ended\",\"Id\":\"chat-ended-event\",\"Type\":\"EVENT\",\"InitialContactId\":\"chat-ended-event-id\"}",
            "topic": "aws/chat",
            "contentType": "application/json"
        ]
        
        return Event(text: nil, timeStamp: isoTime, contentType: ContentType.ended.rawValue, messageId: "chat-ended-event", serializedContent: serializedContent)
    }
    
    static func createDummyMessage(content: String, contentType: String, status: MessageStatus, attachmentId: String? = nil, displayName: String) -> Message {
        let randomId = UUID().uuidString
        
        return Message(
            participant: "CUSTOMER",
            text: content,
            contentType: contentType,
            messageDirection: .Outgoing,
            timeStamp: "", // Empty string for sending messages - no timestamp displayed, sorting handled by transcript logic
            attachmentId: attachmentId,
            messageId: randomId,
            displayName: displayName,
            serializedContent: [:],
            metadata: Metadata(status: status, timeStamp: "", contentType: contentType, eventDirection: .Outgoing, serializedContent: [:]), // Empty timestamp for metadata too
            persistentId: randomId
        )
    }
}
