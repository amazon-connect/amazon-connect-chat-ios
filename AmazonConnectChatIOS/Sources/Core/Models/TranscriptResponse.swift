// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

public class TranscriptResponse: Equatable {
    public static func == (lhs: TranscriptResponse, rhs: TranscriptResponse) -> Bool {
        return lhs.initialContactId == rhs.initialContactId && lhs.nextToken == rhs.nextToken && lhs.transcript == rhs.transcript
    }
    
    public let initialContactId: String
    public let nextToken: String
    public var transcript: [TranscriptItem]

    public init(initialContactId: String, nextToken: String, transcript: [TranscriptItem]) {
        self.initialContactId = initialContactId
        self.nextToken = nextToken
        self.transcript = transcript
    }

    enum CodingKeys: String, CodingKey {
        case initialContactId = "InitialContactId"
        case nextToken = "NextToken"
        case transcript = "Transcript"
    }
}
