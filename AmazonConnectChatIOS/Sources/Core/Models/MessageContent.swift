// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

// MARK: - MessageContent Protocol
public protocol MessageContent {
    static func decode(from text: String) -> MessageContent?
}

// MARK: - Plain Text Content
public struct PlainTextContent: MessageContent {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public static func decode(from text: String) -> MessageContent? {
        return PlainTextContent(text: text)
    }
}

// MARK: - Generic Interactive Template
public struct GenericInteractiveTemplate: Decodable {
    public let templateType: String
    // Other properties common to all interactive message types, if any
}

// MARK: - Interactive Content Protocol
public protocol InteractiveContent: MessageContent {
    static var templateType: String { get }
}

// MARK: - Quick Reply Content
public struct QuickReplyElement: Codable {
    public let title: String
}

public struct QuickReplyContentData: Codable {
    public let title: String
    public let subtitle: String?
    public let elements: [QuickReplyElement]
}

public struct QuickReplyData: Codable {
    public let content: QuickReplyContentData
}

public struct QuickReplyTemplate: Codable {
    public let templateType: String
    public let version: String
    public let data: QuickReplyData
}

public struct QuickReplyContent: InteractiveContent {
    public static let templateType = Constants.QUICK_REPLY // This should match the templateType value for Quick Replies in the JSON

    public let title: String
    public let subtitle: String?
    public let options: [String]

    public static func decode(from text: String) -> MessageContent? {
        guard let jsonData = text.data(using: .utf8) else { return nil }
        do {
            let quickReply = try JSONDecoder().decode(QuickReplyTemplate.self, from: jsonData)
            let options = quickReply.data.content.elements.map { $0.title }
            let title = quickReply.data.content.title
            let subtitle = quickReply.data.content.subtitle
            return QuickReplyContent(title: title, subtitle: subtitle, options: options)
        } catch {
            print("Error decoding QuickReplyContent: \(error)")
            return nil
        }
    }
}

// MARK: - List Picker Content
public struct ListPickerElement: Codable, Hashable, Equatable {
    public let title: String
    public let subtitle: String?
    public let imageType: String?
    public let imageData: String?
}

public struct ListPickerContentData: Codable {
    public let title: String
    public let subtitle: String?
    public let imageType: String?
    public let imageData: String?
    public let elements: [ListPickerElement]
}

public struct ListPickerData: Codable {
    public let content: ListPickerContentData
}

public struct ListPickerTemplate: Codable {
    public let templateType: String
    public let version: String
    public let data: ListPickerData
}

public struct ListPickerContent: InteractiveContent {
    public static let templateType = Constants.LIST_PICKER // This should match the templateType value for List Pickers in the JSON

    public let title: String
    public let subtitle: String?
    public let imageUrl: String?
    public let options: [ListPickerElement]

    public static func decode(from text: String) -> MessageContent? {
        guard let jsonData = text.data(using: .utf8) else { return nil }
        do {
            let listPicker = try JSONDecoder().decode(ListPickerTemplate.self, from: jsonData)
            let title = listPicker.data.content.title
            let subtitle = listPicker.data.content.subtitle
            let options = listPicker.data.content.elements
            let imageUrl = listPicker.data.content.imageData
            return ListPickerContent(title: title, subtitle: subtitle, imageUrl: imageUrl, options: options)
        } catch {
            print("Error decoding ListPickerContent: \(error)")
            return nil
        }
    }
}

// MARK: - Additional Interactive Content Types
// Add additional structs here following the pattern of QuickReplyContent for each new type of interactive content.
