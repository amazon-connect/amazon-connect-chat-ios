// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public enum MessageType {
    case Sender
    case Receiver
    case Common
}

public struct Message: Identifiable, Equatable, Hashable {
    public var participant: String?
    public var text: String
    public var id = UUID()
    public var contentType: String
    public var messageType: MessageType
    public var timeStamp: String
    public var messageID: String?
    public var status: String?
    public var isRead: Bool = false

    public init(participant: String?, text: String, contentType: String, messageType: MessageType, timeStamp: String, messageID: String? = nil, status: String? = nil, isRead: Bool = false) {
        self.participant = participant
        self.text = text
        self.contentType = contentType
        self.messageType = messageType
        self.timeStamp = timeStamp
        self.messageID = messageID
        self.status = status
        self.isRead = isRead
    }

    public var content: MessageContent? {
        switch contentType {
        case ContentType.plainText.rawValue:
            return PlainTextContent.decode(from: text)
        case ContentType.richText.rawValue:
            // A rich text content class could be created later as complexity increases
            return PlainTextContent.decode(from: text)
        case ContentType.interactiveText.rawValue:
            return decodeInteractiveContent(from: text)
        default:
            // Handle or log unsupported content types
            return nil
        }
    }
    
    // Helper method to decode interactive content
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
            // Add cases for each interactive message type, decoding as appropriate.
            default:
                print("Unsupported interactive content type: \(genericTemplate.templateType)")
                return nil
        }
    }
}
