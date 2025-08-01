// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0


import Foundation

// Data structure to hold complete event information
public struct EventData: Equatable {
    public let absoluteTime: String?
    public let contentType: String?
    public let type: String?
    public let participantId: String?
    public let displayName: String?
    public let participantRole: String?
    public let initialContactId: String?
    public let messageId: String?
    
    public init(absoluteTime: String?, contentType: String?, type: String?, participantId: String?, displayName: String?, participantRole: String?, initialContactId: String?, messageId: String?) {
        self.absoluteTime = absoluteTime
        self.contentType = contentType
        self.type = type
        self.participantId = participantId
        self.displayName = displayName
        self.participantRole = participantRole
        self.initialContactId = initialContactId
        self.messageId = messageId
    }
}

public enum ContentType: String {
    case typing = "application/vnd.amazonaws.connect.event.typing"
    case connectionAcknowledged = "application/vnd.amazonaws.connect.event.connection.acknowledged"
    case messageDelivered = "application/vnd.amazonaws.connect.event.message.delivered"
    case messageRead = "application/vnd.amazonaws.connect.event.message.read"
    case metaData = "application/vnd.amazonaws.connect.event.message.metadata"
    case joined = "application/vnd.amazonaws.connect.event.participant.joined"
    case left = "application/vnd.amazonaws.connect.event.participant.left"
    case ended = "application/vnd.amazonaws.connect.event.chat.ended"
    case plainText = "text/plain"
    case richText = "text/markdown"
    case interactiveText = "application/vnd.amazonaws.connect.message.interactive"
    case interactiveResponse = "application/vnd.amazonaws.connect.message.interactive.response"
    case authenticationInitiated = "application/vnd.amazonaws.connect.event.authentication.initiated"
    case authenticationSuccessful = "application/vnd.amazonaws.connect.event.authentication.succeeded"
    case authenticationFailed = "application/vnd.amazonaws.connect.event.authentication.failed"
    case authenticationTimeout = "application/vnd.amazonaws.connect.event.authentication.timeout"
    case authenticationExpired = "application/vnd.amazonaws.connect.event.authentication.expired"
    case authenticationCancelled = "application/vnd.amazonaws.connect.event.authentication.cancelled"
    case participantDisplayNameUpdated = "application/vnd.amazonaws.connect.event.participant.displayname.updated"
    case participantActive = "application/vnd.amazonaws.connect.event.participant.active"
    case participantInactive = "application/vnd.amazonaws.connect.event.participant.inactive"
    case transferSucceeded = "application/vnd.amazonaws.connect.event.transfer.succeeded"
    case transferFailed = "application/vnd.amazonaws.connect.event.transfer.failed"
    case participantIdle = "application/vnd.amazonaws.connect.event.participant.idle"
    case participantReturned = "application/vnd.amazonaws.connect.event.participant.returned"
    case participantInvited = "application/vnd.amazonaws.connect.event.participant.invited"
    case autoDisconnection = "application/vnd.amazonaws.connect.event.participant.autodisconnection"
    case chatRehydrated = "application/vnd.amazonaws.connect.event.chat.rehydrated"
}

public enum MessageReceiptType: String {
    case messageDelivered = "application/vnd.amazonaws.connect.event.message.delivered"
    case messageRead = "application/vnd.amazonaws.connect.event.message.read"
    
    func toContentType() -> ContentType {
        switch self {
        case .messageDelivered:
            return .messageDelivered
        case .messageRead:
            return .messageRead
        }
    }
}

public enum WebSocketMessageType: String {
    case message = "MESSAGE"
    case event = "EVENT"
    case attachment = "ATTACHMENT"
    case messageMetadata = "MESSAGEMETADATA"
}


enum ChatEvent: Equatable {
    case connectionEstablished
    case connectionReEstablished
    case chatEnded
    case connectionBroken
    case participantIdle(data: EventData)
    case participantReturned(data: EventData)
    case autoDisconnection(data: EventData)
    case typing(data: EventData)
    case readReceipt(data: EventData)
    case deliveredReceipt(data: EventData)
    case participantInvited(data: EventData)
    case participantDisplayNameUpdated(data: EventData)
    case chatRehydrated(data: EventData)
}
