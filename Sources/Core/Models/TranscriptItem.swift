// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation

public protocol TranscriptItemProtocol: Identifiable, Equatable, Hashable, ObservableObject {
    var id: String { get }
    var persistentId: String { get }
    var timeStamp: String { get }
    var contentType: String { get set }
    var serializedContent: [String: Any]? { get set }
    var viewResource: ViewResource? { get set }
}

public class TranscriptItem: TranscriptItemProtocol {
    public private(set) var id: String
    public private(set) var persistentId: String
    public private(set) var timeStamp: String
    public var contentType: String
    public var serializedContent: [String: Any]?
    public var viewResource: ViewResource?

    public init(timeStamp: String, contentType: String, id: String?, serializedContent: [String: Any]?, viewResource: ViewResource? = nil) {
        let randomId = UUID().uuidString
        self.timeStamp = timeStamp
        self.contentType = contentType
        self.serializedContent = serializedContent
        self.viewResource = viewResource
        self.id = id ?? randomId
        self.persistentId = id ?? randomId
    }

    public static func == (lhs: TranscriptItem, rhs: TranscriptItem) -> Bool {
        return lhs.id == rhs.id && lhs.timeStamp == rhs.timeStamp && lhs.contentType == rhs.contentType
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(timeStamp)
        hasher.combine(contentType)
    }
    
    // Internal methods to update id and timeStamp
    internal func updateId(_ newId: String) {
        self.id = newId
    }
    
    internal func updateTimeStamp(_ newTimeStamp: String) {
        self.timeStamp = newTimeStamp
    }
    
    internal func updatePersistentId(_ newPersistentId: String) {
        self.persistentId = newPersistentId
    }
}

public struct TranscriptData {
    public let transcriptList: [TranscriptItem]
    public let previousTranscriptNextToken: String?
    
    public init(transcriptList: [TranscriptItem], previousTranscriptNextToken: String?) {
        self.transcriptList = transcriptList
        self.previousTranscriptNextToken = previousTranscriptNextToken
    }
}
