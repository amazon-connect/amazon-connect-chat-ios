// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public enum MessageDirection {
    case Outgoing
    case Incoming
    case Common
}

public protocol MessageProtocol: TranscriptItemProtocol {
    var participant: String { get set }
    var text: String { get set }
    var contentType: String { get set }
    var messageId: String? { get set }
    var displayName: String? { get set }
    var messageDirection: MessageDirection? { get set }
    var metadata: (any MetadataProtocol)? { get set }
}

public class Message: TranscriptItem, MessageProtocol {
    public var participant: String
    public var text: String
    public var messageDirection: MessageDirection?
    public var messageId: String?
    public var attachmentId: String?
    public var displayName: String?
    @Published public var metadata: (any MetadataProtocol)?

    public init(participant: String, text: String, contentType: String, messageDirection: MessageDirection? = nil, timeStamp: String, attachmentId: String? = nil, messageID: String? = nil,
                displayName: String? = nil, serializedContent: [String: Any], metadata: (any MetadataProtocol)? = nil) {
        self.participant = participant
        self.text = text
        self.messageDirection = messageDirection
        self.messageId = messageID
        self.metadata = metadata
        self.displayName = displayName
        self.attachmentId = attachmentId
        super.init(timeStamp: timeStamp, contentType: contentType, serializedContent: serializedContent)
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
            print("Unsupported content type: \(contentType)")
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
        case TimePickerContent.templateType:
            return TimePickerContent.decode(from: text)
        case PanelContent.templateType:
            return PanelContent.decode(from: text)
        case CarouselContent.templateType:
            return CarouselContent.decode(from: text)
        default:
            print("Unsupported interactive content type: \(genericTemplate.templateType)")
            return nil
        }
    }
}
