// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public enum MessageDirection {
    case Outgoing
    case Incoming
    case Common
}

protocol MessageProtocol: TranscriptItemProtocol {
    var participant: String { get set }
    var text: String { get set }
    var contentType: String { get set }
    var messageID: String? { get set }
    var messageDirection: MessageDirection? { get set }
}

public class Message: TranscriptItem, MessageProtocol {
    public var participant: String
    public var text: String
    public var messageDirection: MessageDirection?
    public var messageID: String?

//    public static func == (lhs: Message, rhs: Message) -> Bool {
//        return lhs.id == rhs.id && lhs.timeStamp == rhs.timeStamp && lhs.text == rhs.text && lhs.participant == rhs.participant && lhs.contentType == rhs.contentType && lhs.messageID == rhs.messageID && lhs.messageDirection == rhs.messageDirection
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(timeStamp)
//        hasher.combine(text)
//        hasher.combine(participant)
//        hasher.combine(contentType)
//        hasher.combine(messageID)
//        hasher.combine(messageDirection)
//    }
    
    public init(participant: String, text: String, contentType: String, messageDirection: MessageDirection? = nil, timeStamp: String, messageID: String? = nil, status: String? = nil, isRead: Bool = false) {
        self.participant = participant
        self.text = text
        self.messageDirection = messageDirection
        self.messageID = messageID
        super.init(timeStamp: timeStamp, contentType: contentType)
    }
    
    public var content: MessageContent? {
        switch contentType {
        case ContentType.plainText.rawValue:
            return PlainTextContent.decode(from: text)
        case ContentType.richText.rawValue:
            // Placeholder for a future rich text content class
            return PlainTextContent.decode(from: text)
        case ContentType.interactiveText.rawValue:
            return decodeInteractiveContent(from: text)
        default:
            // Handle or log unsupported content types
            return nil
        }
    }
    
    private func decodeInteractiveContent(from text: String) -> MessageContent? {
        guard let jsonData = text.data(using: .utf8),
              let genericTemplate = try? JSONDecoder().decode(GenericInteractiveTemplate.self, from: jsonData) else {
            return nil
        }
        switch genericTemplate.templateType {
        case QuickReplyContent.templateType:
            return QuickReplyContent.decode(from: text)
        case ListPickerContent.templateType:
            return ListPickerContent.decode(from: text)
        default:
            print("Unsupported interactive content type: \(genericTemplate.templateType)")
            return nil
        }
    }
}
