// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

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

// MARK: - Panel
public struct PanelElement: Codable {
    public let title: String
}

public struct PanelContentData: Codable {
    public let title: String
    public let subtitle: String?
    public let imageType: String?
    public let imageData: String?
    public let imageDescription: String?
    public let elements: [PanelElement]
}

public struct PanelReplyMessage: Codable {
    public let title: String
    public let subtitle: String?
}

public struct PanelData: Codable {
    public let replyMessage: PanelReplyMessage?
    public let content: PanelContentData
}

public struct PanelTemplate: Codable {
    public let templateType: String
    public let version: String
    public let data: PanelData
}

public struct PanelContent: InteractiveContent {
    public static let templateType = Constants.PANEL

    public let title: String
    public let subtitle: String?
    public let imageUrl: String?
    public let imageDescription: String?
    public let options: [PanelElement]

    public static func decode(from text: String) -> MessageContent? {
        guard let jsonData = text.data(using: .utf8) else { return nil }
        do {
            let panel = try JSONDecoder().decode(PanelTemplate.self, from: jsonData)
            let title = panel.data.content.title
            let subtitle = panel.data.content.subtitle
            let imageUrl = panel.data.content.imageData
            let imageDescription = panel.data.content.imageDescription
            let options = panel.data.content.elements
            return PanelContent(title: title, subtitle: subtitle, imageUrl: imageUrl, imageDescription: imageDescription, options: options)
        } catch {
            print("Error decoding PanelContent: \(error)")
            return nil
        }
    }
}

// MARK: - TimePicker
public struct TimeSlot: Codable {
    public let date: String
    public let duration: Int
}

public struct Location: Codable {
    public let latitude: Double
    public let longitude: Double
    public let title: String
    public let radius: Int?
}

public struct TimePickerContentData: Codable {
    public let title: String
    public let subtitle: String?
    public let timeZoneOffset: Int?
    public let location: Location?
    public let timeslots: [TimeSlot]
}

public struct TimePickerReplyMessage: Codable {
    public let title: String?
    public let subtitle: String?
}

public struct TimePickerData: Codable {
    public let replyMessage: TimePickerReplyMessage?
    public let content: TimePickerContentData
}

public struct TimePickerTemplate: Codable {
    public let templateType: String
    public let version: String
    public let data: TimePickerData
}

public struct TimePickerContent: InteractiveContent {
    public static let templateType = Constants.TIME_PICKER

    public let title: String
    public let subtitle: String?
    public let timeZoneOffset: Int?
    public let location: Location?
    public let timeslots: [TimeSlot]

    public static func decode(from text: String) -> MessageContent? {
        guard let jsonData = text.data(using: .utf8) else { return nil }
        do {
            let timePicker = try JSONDecoder().decode(TimePickerTemplate.self, from: jsonData)
            let title = timePicker.data.content.title
            let subtitle = timePicker.data.content.subtitle
            let timeZoneOffset = timePicker.data.content.timeZoneOffset
            let location = timePicker.data.content.location
            let timeslots = timePicker.data.content.timeslots
            return TimePickerContent(title: title, subtitle: subtitle, timeZoneOffset: timeZoneOffset, location: location, timeslots: timeslots)
        } catch {
            print("Error decoding TimePickerContent: \(error)")
            return nil
        }
    }
}

// MARK: - Carousel
public struct CarouselElement: Codable {
    public let templateIdentifier: String
    public let templateType: String
    public let version: String
    public let data: PanelData
}

public struct CarouselContentData: Codable {
    public let title: String
    public let elements: [CarouselElement]
}

public struct CarouselData: Codable {
    public let content: CarouselContentData
}

public struct CarouselTemplate: Codable {
    public let templateType: String
    public let version: String
    public let data: CarouselData
}

public struct CarouselContent: InteractiveContent {
    public static let templateType = Constants.CAROUSEL

    public let title: String
    public let elements: [CarouselElement]

    public static func decode(from text: String) -> MessageContent? {
        guard let jsonData = text.data(using: .utf8) else { return nil }
        do {
            let carousel = try JSONDecoder().decode(CarouselTemplate.self, from: jsonData)
            let title = carousel.data.content.title
            let elements = carousel.data.content.elements
            return CarouselContent(title: title, elements: elements)
        } catch {
            print("Error decoding CarouselContent: \(error)")
            return nil
        }
    }
}


