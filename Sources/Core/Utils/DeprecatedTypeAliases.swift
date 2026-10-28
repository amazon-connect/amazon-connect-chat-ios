// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant

// Source-compatibility aliases for the 2.x type names, which came from the deprecated AWS Mobile
// SDK and appeared in this SDK's public API. They let existing call sites — most importantly
// `AWSClient` subclasses registered via `GlobalConfig.customAWSClient` — compile against 3.0 with
// a warning rather than an error.
//
// These are source-compatible only, not behaviour-compatible: the new models are value types with
// renamed fields. They may be removed in a future major version.

@available(*, deprecated, renamed: "Region")
public typealias AWSRegionType = Region

@available(*, deprecated, renamed: "ScanDirection")
public typealias AWSConnectParticipantScanDirection = ScanDirection

@available(*, deprecated, renamed: "SortKey")
public typealias AWSConnectParticipantSortKey = SortKey

@available(*, deprecated, renamed: "CreateParticipantConnectionOutput")
public typealias AWSConnectParticipantCreateParticipantConnectionResponse = CreateParticipantConnectionOutput

@available(*, deprecated, renamed: "DisconnectParticipantOutput")
public typealias AWSConnectParticipantDisconnectParticipantResponse = DisconnectParticipantOutput

@available(*, deprecated, renamed: "SendMessageOutput")
public typealias AWSConnectParticipantSendMessageResponse = SendMessageOutput

@available(*, deprecated, renamed: "SendEventOutput")
public typealias AWSConnectParticipantSendEventResponse = SendEventOutput

@available(*, deprecated, renamed: "GetTranscriptInput")
public typealias AWSConnectParticipantGetTranscriptRequest = GetTranscriptInput

@available(*, deprecated, renamed: "GetTranscriptOutput")
public typealias AWSConnectParticipantGetTranscriptResponse = GetTranscriptOutput

@available(*, deprecated, renamed: "StartAttachmentUploadOutput")
public typealias AWSConnectParticipantStartAttachmentUploadResponse = StartAttachmentUploadOutput

@available(*, deprecated, renamed: "CompleteAttachmentUploadOutput")
public typealias AWSConnectParticipantCompleteAttachmentUploadResponse = CompleteAttachmentUploadOutput

@available(*, deprecated, renamed: "GetAttachmentOutput")
public typealias AWSConnectParticipantGetAttachmentResponse = GetAttachmentOutput

@available(*, deprecated, renamed: "DescribeViewOutput")
public typealias AWSConnectParticipantDescribeViewResponse = DescribeViewOutput

@available(*, deprecated, message: "Use ConnectParticipantClientTypes.Item. Note `identifier` is now `id` and `types` is now `type`.")
public typealias AWSConnectParticipantItem = ConnectParticipantClientTypes.Item

@available(*, deprecated, message: "Use ConnectParticipantClientTypes.StartPosition. Note `identifier` is now `id`, and `mostRecent` is a non-optional Int.")
public typealias AWSConnectParticipantStartPosition = ConnectParticipantClientTypes.StartPosition

@available(*, deprecated, renamed: "ConnectParticipantClientTypes.MessageMetadata")
public typealias AWSConnectParticipantMessageMetadata = ConnectParticipantClientTypes.MessageMetadata

@available(*, deprecated, renamed: "ConnectParticipantClientTypes.ParticipantRole")
public typealias AWSConnectParticipantParticipantRole = ConnectParticipantClientTypes.ParticipantRole

@available(*, deprecated, renamed: "ConnectParticipantClientTypes.ChatItemType")
public typealias AWSConnectParticipantChatItemType = ConnectParticipantClientTypes.ChatItemType
