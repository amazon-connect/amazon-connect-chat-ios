// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public protocol TranscriptItemProtocol: Identifiable, Equatable, Hashable, ObservableObject {
    var id: String { get }
    var timeStamp: String { get set }
    var contentType: String { get set }
    var serializedContent: [String: Any]? { get set }
//    func copy() -> any TranscriptItemProtocol
}

public class TranscriptItem: TranscriptItemProtocol {
    public var id: String
    public var timeStamp: String
    public var contentType: String
    public var serializedContent: [String: Any]?

    public init(timeStamp: String, contentType: String, id: String?, serializedContent: [String: Any]?) {
        self.timeStamp = timeStamp
        self.contentType = contentType
        self.serializedContent = serializedContent
        self.id = id ?? UUID().uuidString
    }

    public static func == (lhs: TranscriptItem, rhs: TranscriptItem) -> Bool {
        return lhs.id == rhs.id && lhs.timeStamp == rhs.timeStamp && lhs.contentType == rhs.contentType
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(timeStamp)
        hasher.combine(contentType)
    }
    
//    public func copy() -> any TranscriptItemProtocol {
//            return TranscriptItem(timeStamp: self.timeStamp, contentType: self.contentType, id: self.id, serializedContent: self.serializedContent)
//        }
}
