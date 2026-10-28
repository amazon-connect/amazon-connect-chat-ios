// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant

/// The direction to scan the transcript from the start position.
public enum ScanDirection: String, Sendable, CaseIterable {
    case forward = "FORWARD"
    case backward = "BACKWARD"
}

/// The sort order for records returned by `getTranscript`.
public enum SortKey: String, Sendable, CaseIterable {
    case ascending = "ASCENDING"
    case descending = "DESCENDING"
}

extension ScanDirection {
    var sdkValue: ConnectParticipantClientTypes.ScanDirection {
        switch self {
        case .forward: return .forward
        case .backward: return .backward
        }
    }

    /// Returns `nil` for values the service adds after this release, so callers keep their default.
    init?(sdkValue: ConnectParticipantClientTypes.ScanDirection?) {
        switch sdkValue {
        case .some(.forward): self = .forward
        case .some(.backward): self = .backward
        default: return nil
        }
    }
}

extension SortKey {
    var sdkValue: ConnectParticipantClientTypes.SortKey {
        switch self {
        case .ascending: return .ascending
        case .descending: return .descending
        }
    }

    /// Returns `nil` for values the service adds after this release, so callers keep their default.
    init?(sdkValue: ConnectParticipantClientTypes.SortKey?) {
        switch sdkValue {
        case .some(.ascending): self = .ascending
        case .some(.descending): self = .descending
        default: return nil
        }
    }
}
