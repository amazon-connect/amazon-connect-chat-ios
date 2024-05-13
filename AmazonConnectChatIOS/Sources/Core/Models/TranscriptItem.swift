// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

protocol TranscriptItemProtocol: Identifiable, Equatable, Hashable {
    var id: UUID { get }
    var timeStamp: String { get set }
    var contentType: String { get set }
}

public class TranscriptItem: TranscriptItemProtocol {
    public var id = UUID()
    public var timeStamp: String
    public var contentType: String

    public init(timeStamp: String, contentType: String) {
        self.timeStamp = timeStamp
        self.contentType = contentType
    }

    public static func == (lhs: TranscriptItem, rhs: TranscriptItem) -> Bool {
        return lhs.id == rhs.id && lhs.timeStamp == rhs.timeStamp && lhs.contentType == rhs.contentType
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(timeStamp)
        hasher.combine(contentType)
    }
}
