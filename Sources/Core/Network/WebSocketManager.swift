// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant
import Combine
import UIKit

enum EventTypes {
    static let subscribe = "{\"topic\": \"aws/subscribe\", \"content\": {\"topics\": [\"aws/chat\"]}})"
    static let heartbeat = "{\"topic\": \"aws/heartbeat\"}"
    static let deepHeartbeat = "{\"topic\": \"aws/ping\"}"
}

protocol WebSocketTask {
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void)
    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
    func resume()
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
}

protocol WebsocketManagerProtocol {
    var eventPublisher: PassthroughSubject<ChatEvent, Never> { get }
    var transcriptPublisher: PassthroughSubject<(TranscriptItem, Bool), Never> { get }
    func connect(wsUrl: URL?, isReconnect: Bool?)
    func disconnect(reason: String?)
    func formatAndProcessTranscriptItems(_ transcriptItems: [AWSConnectParticipantItem]) -> [TranscriptItem]
    func suspendWebSocketConnection()
    func resumeWebSocketConnection()
}

extension URLSessionWebSocketTask: WebSocketTask {}

class WebsocketManager: NSObject, WebsocketManagerProtocol {
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptPublisher = PassthroughSubject<(TranscriptItem, Bool), Never>()

    private var session: URLSession?
    private var wsUrl: URL?
    var heartbeatManager: HeartbeatManager?
    var deepHeartbeatManager: HeartbeatManager?
    var websocketTask: WebSocketTask?
    var isReconnectFlow = false
    var isSuspended = false

    // Adding few more callbacks
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    var onError: ((Error?) -> Void)?
    
    init(wsUrl: URL) {
        self.wsUrl = wsUrl
        super.init()
        self.connect()
        self.initializeHeartbeatManagers()
        self.addNetworkNotificationObserver()
        self.addLifecycleObservers()
    }
    
    func connect(wsUrl: URL? = nil, isReconnect: Bool? = false) {
        if let isReconnect {
            self.isReconnectFlow = isReconnect
        }
        disconnect(reason: "Connecting...") // Ensure previous WebSocket tasks are properly closed
        
        if let wsTask = self.websocketTask {
            wsTask.cancel(with: .goingAway, reason: nil)
        }
        if let nonEmptyWsUrl = wsUrl {
            self.wsUrl = nonEmptyWsUrl
        }
        if let webSocketUrl = self.wsUrl {
            self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
            self.websocketTask = self.session?.webSocketTask(with: webSocketUrl)
            websocketTask?.resume()
            receiveMessage()
        } else {
            SDKLogger.logger.logError("No WebSocketURL found")
            return
        }
    }
    
    func sendWebSocketMessage(string message: String) {
        let messageToSend = URLSessionWebSocketTask.Message.string(message)
        websocketTask?.send(messageToSend) { error in
            if let error = error {
                SDKLogger.logger.logError("Failed to send message: \(error)")
            } else {
                SDKLogger.logger.logDebug("Message sent: \(message)")
            }
        }
    }
    
    func receiveMessage() {
        websocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                SDKLogger.logger.logError("Failed to receive message, Websocket connection might be closed: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    SDKLogger.logger.logDebug("Received text in receiveMessage() \(text)")
                    self?.handleWebsocketTextEvent(text: text)
                case .data(_):
                    SDKLogger.logger.logDebug("Received data from websocket")
                @unknown default:
                    SDKLogger.logger.logError("Received an unknown message type, which is not handled.")
                }
                self?.receiveMessage()
            }
        }
    }
    
    // MARK: - WebSocketDelegate
    func handleError(_ error: Error?) {
        if let nsError = error as? NSError {
            switch (nsError.domain) {
            case NSPOSIXErrorDomain:
                if (nsError.code == WebSocketErrorCodes.SOFTWARE_ABORT.rawValue
                    || nsError.code == WebSocketErrorCodes.OPERATION_TIMED_OUT.rawValue) {
                    self.reestablishConnectionIfChatActive()
                }
                break
            case NSURLErrorDomain:
                if (nsError.code == WebSocketErrorCodes.NETWORK_DISCONNECTED.rawValue) {
                    SDKLogger.logger.logDebug("WebSocket disconnected due to lost network connection")
                } else if (nsError.code == WebSocketErrorCodes.BAD_SERVER_RESPONSE.rawValue) {
                    self.reestablishConnectionIfChatActive()
                }
                break
            default:
                SDKLogger.logger.logDebug("DEBUG - DOMAIN: \(nsError.domain)")
                SDKLogger.logger.logDebug("DEBUG - CODE: \(nsError.code)")
                SDKLogger.logger.logDebug("DEBUG - DESCRIPTION: \(nsError.localizedDescription)")
            }
        }
        
        if let e = error {
            SDKLogger.logger.logError("websocket encountered an error: \(e.localizedDescription)")
        } else {
            SDKLogger.logger.logError("websocket encountered an error")
        }
        self.onError?(error)
    }
    
    func disconnect(reason: String?) {
        resetHeartbeatManagers()
        let reasonData = reason?.data(using: .utf8)
        websocketTask?.cancel(with: .goingAway, reason: reasonData)
        websocketTask = nil
    }
    
    func suspendWebSocketConnection() {
        self.isSuspended = true
        self.disconnect(reason: "WebSocket suspended")
    }
    
    func resumeWebSocketConnection() {
        self.isSuspended = false
        self.reestablishConnectionIfChatActive()
    }
    
    func reestablishConnectionIfChatActive() {
        if !ChatSession.shared.isChatSessionActive() {
            SDKLogger.logger.logDebug("WebSocket reconnection aborted due to inactive chat session")
            return
        }
        if !NetworkConnectionManager.shared.checkConnectivity() {
            SDKLogger.logger.logDebug("WebSocket reconnection aborted due to missing network connectivity")
            return
        }
        if self.isSuspended {
            SDKLogger.logger.logDebug("WebSocket reconnection aborted due to suspended websocket connection")
            return
        }
        NotificationCenter.default.post(name: .requestNewWsUrl, object: nil)
    }

    
    func addNetworkNotificationObserver() {
        NotificationCenter.default.addObserver(forName: .networkConnected, object: nil, queue: .main) { _ in
            self.reestablishConnectionIfChatActive()
        }
    }
    
    func addLifecycleObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) {
            [weak self] notification in
            if (ChatSession.shared.isChatSessionActive()) {
                self?.disconnect(reason: "App backgrounded")
            }
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) {
            [weak self] notification in
            self?.reestablishConnectionIfChatActive()
        }
    }
    
    func handleWebsocketTextEvent(text: String) {
        guard let jsonData = text.data(using: .utf8) else { return }
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                processJsonContent(json)
            }
        } catch {
            SDKLogger.logger.logError("Error parsing JSON from WebSocket: \(error)")
        }
    }
    
    func processJsonContent(_ json: [String: Any]) {
        if let topic = json["topic"] as? String {
            switch topic {
            case "aws/ping":
                if (json["statusCode"] as? Int == 200 && json["statusContent"] as? String == "OK") {
                    self.deepHeartbeatManager?.heartbeatReceived()
                } else {
                    SDKLogger.logger.logError("Deep heartbeat failed. Status: \(json["statusCode"] ?? "nil"), StatusContent: \(json["statusContent"] ?? "nil")")
                }
                break
            case "aws/heartbeat":
                self.heartbeatManager?.heartbeatReceived()
                break
            case "aws/chat":
                websocketDidReceiveMessage(json: json)
            default:
                break
            }
        }
    }
    
    func websocketDidReceiveMessage(json: [String: Any]) {
        if let item = processJsonContentAndGetItem(json) {
            transcriptPublisher.send((item, true))
        }
    }
    
    func processJsonContentAndGetItem(_ json: [String: Any]) -> TranscriptItem? {
        let content = json["content"] as? String
        
        if let stringContent = content,
           let innerJson = try? JSONSerialization.jsonObject(with: Data(stringContent.utf8), options: []) as? [String: Any] {
            guard let typeString = innerJson["Type"] as? String, let type = WebSocketMessageType(rawValue: typeString) else {
                SDKLogger.logger.logError("Unknown websocket message type: \(String(describing: innerJson["Type"]))")
                return nil
            }
            switch type {
                case .message:
                    return self.handleMessage(innerJson, json)
                case .event:
                    guard let eventTypeString = innerJson["ContentType"] as? String, let eventType = ContentType(rawValue: eventTypeString) else {
                        SDKLogger.logger.logError("Unknown event type \(String(describing: innerJson["ContentType"]))")
                        return nil
                    }
                    
                    switch eventType {
                    case .joined:
                        // Handle participant joined event
                        return handleParticipantEvent(innerJson, json)
                    case .left:
                        // Handle participant left event
                        return handleParticipantEvent(innerJson, json)
                    case .typing:
                        // Handle typing event
                        return handleTyping(innerJson, json)
                    case .ended:
                        // Handle chat ended event
                        return handleChatEnded(innerJson, json)
                    case .participantIdle, .participantReturned, .autoDisconnection, .messageRead, .messageDelivered, .participantInvited, .chatRehydrated:
                        // Handle all participant state change events with common function
                        return handleParticipantStateChange(innerJson, json)
                    default:
                        SDKLogger.logger.logError("Unknown event: \(String(describing: eventType))")
                    }
                case .attachment:
                    return handleAttachment(innerJson, json)
                case .messageMetadata:
                    return handleMetadata(innerJson, json)
            }
            SDKLogger.logger.logError("Unknown message type: \(String(describing: type))")
            return nil
        }
        SDKLogger.logger.logError("Unable to parse json: \(String(describing: content))")
        return nil
    }
    
    // MARK: - Reconnection / State Management
    private func getRetryDelay(numAttempts: Double) -> Double {
        let calculatedDelay = pow(2, numAttempts) * 2;
        return calculatedDelay <= 30 ? calculatedDelay : 30
    }
    
    // MARK: - Heartbeat Logic
    
    func initializeHeartbeatManagers() {
        self.heartbeatManager = HeartbeatManager(isDeepHeartbeat: false, sendHeartbeatCallback: sendHeartbeat, missedHeartbeatCallback: onHeartbeatMissed)
        self.deepHeartbeatManager = HeartbeatManager(isDeepHeartbeat: true, sendHeartbeatCallback: sendDeepHeartbeat, missedHeartbeatCallback: onDeepHeartbeatMissed)
    }
    
    func resetHeartbeatManagers() {
        self.heartbeatManager?.stopHeartbeat()
        self.deepHeartbeatManager?.stopHeartbeat()
    }
    
    func startHeartbeats() {
        self.heartbeatManager?.startHeartbeat()
        self.deepHeartbeatManager?.startHeartbeat()
    }
    
    func sendHeartbeat() {
        self.sendWebSocketMessage(string: EventTypes.heartbeat)
    }
    
    func sendDeepHeartbeat() {
        self.sendWebSocketMessage(string: EventTypes.deepHeartbeat)
    }
    
    func onHeartbeatMissed() {
        if !ChatSession.shared.isChatSessionActive() {
            return
        }
        if NetworkConnectionManager.shared.checkConnectivity() {
            SDKLogger.logger.logError("Heartbeat missed")
        } else {
            SDKLogger.logger.logError("Device is not connected to the internet")
        }
    }
    
    func onDeepHeartbeatMissed() {
        if !ChatSession.shared.isChatSessionActive() {
            return
        }
        ChatSession.shared.onDeepHeartbeatFailure?()
        if NetworkConnectionManager.shared.checkConnectivity() {
            SDKLogger.logger.logError("Deep heartbeat missed")
        } else {
            SDKLogger.logger.logError("Device is not connected to the internet")
        }
        self.eventPublisher.send(.connectionBroken)
    }
}


// MARK: - URLSessionWebSocketDelegate

extension WebsocketManager: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        SDKLogger.logger.logDebug("Websocket connection successfully established")
        self.onConnected?()
        self.eventPublisher.send(self.isReconnectFlow ? .connectionReEstablished : .connectionEstablished)
        self.sendWebSocketMessage(string: EventTypes.subscribe)
        self.startHeartbeats()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
          let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason provided"
        SDKLogger.logger.logDebug("WebSocket closed with code: \(closeCode) and reason: \(reasonString)")
          self.onDisconnected?()
          self.isReconnectFlow = false
      }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            SDKLogger.logger.logError("WebSocket connection completed with error: \(error.localizedDescription)")
            handleError(error)
        } else {
            SDKLogger.logger.logDebug("WebSocket task completed successfully without errors.")
        }
        self.onDisconnected?()
    }
}


// MARK: - Formatting extension

extension WebsocketManager {
    func formatAndProcessTranscriptItems(_ transcriptItems: [AWSConnectParticipantItem]) -> [TranscriptItem] {
        return transcriptItems.compactMap { item in
            // Create a dictionary with the necessary fields
            let participantRole = CommonUtils().convertParticipantRoleToString(item.participantRole.rawValue)
            
            // Process attachments
            var attachmentsArray: [[String: Any]] = []
            if let attachments = item.attachments {
                attachmentsArray = attachments.map { attachment in
                    [
                        "AttachmentId": attachment.attachmentId ?? "",
                        "AttachmentName": attachment.attachmentName ?? "",
                        "ContentType": attachment.contentType ?? "",
                        "Status": attachment.status.rawValue
                    ]
                }
            }
            
            let messageContentDict: [String: Any] = [
                "Id": item.identifier ?? "",
                "ParticipantRole": "\(participantRole)",
                "AbsoluteTime": item.absoluteTime ?? "",
                "ContentType": item.contentType ?? "",
                "Content": item.content ?? "",
                "Type": CommonUtils().convertParticipantTypeToString(item.types.rawValue),
                "DisplayName": item.displayName ?? "",
                "Attachments": attachmentsArray,
                "IsFromPastSession": true, // Mark all these items as coming from a past session
                "MessageMetadata": CommonUtils().convertMessageMetadataToDict(item.messageMetadata)
            ]
            
            // Serialize the dictionary to JSON string
            guard let messageContentData = try? JSONSerialization.data(withJSONObject: messageContentDict, options: []),
                  let messageContentString = String(data: messageContentData, encoding: .utf8) else {
                SDKLogger.logger.logError("Failed to serialize message content to JSON string")
                return nil
            }
            
            // Wrap the JSON string properly as a nested object
            let wrappedMessage: [String: Any] = [
                "content": messageContentString
            ]

            if let wrappedJsonData = try? JSONSerialization.data(withJSONObject: wrappedMessage, options: []),
               let json = try? JSONSerialization.jsonObject(with: wrappedJsonData, options: []) as? [String: Any] {
                   // Process the JSON content and return a TranscriptItem
                   let transcriptItem = self.processJsonContentAndGetItem(json)
                   if let validItem = transcriptItem {
                       transcriptPublisher.send((validItem, false))
                   }
                   return transcriptItem
               }

            SDKLogger.logger.logError("Failed to wrap and deserialize JSON.")
            return nil

        }
    }

    
    // MARK: - Handle Events
    func handleMessage(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let participantRole = innerJson["ParticipantRole"] as! String
        let messageId = innerJson["Id"] as! String
        let messageText = innerJson["Content"] as! String
        let displayName = innerJson["DisplayName"] as! String
        let time = innerJson["AbsoluteTime"] as! String

        
        return Message(
            participant: participantRole,
            text: messageText,
            contentType: innerJson["ContentType"] as! String,
            timeStamp: time,
            messageId: messageId,
            displayName: displayName,
            serializedContent: serializedContent,
            metadata: (innerJson["MessageMetadata"] != nil) ? handleMetadata(innerJson, serializedContent) as? (any MetadataProtocol) : nil
        )
    }
    
    func handleAttachment(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem?  {
        let participantRole = innerJson["ParticipantRole"] as! String
        let messageId = innerJson["Id"] as! String
        let time = innerJson["AbsoluteTime"] as! String
        let displayName = innerJson["DisplayName"] as! String

        var attachmentName: String? = nil
        var contentType: String? = nil
        var attachmentId: String? = nil
        if let attachmentsArray = innerJson["Attachments"] as? [[String: Any]],
           let firstAttachment = attachmentsArray.first,
           let firstAttachmentName = firstAttachment["AttachmentName"] as? String,
           let firstAttachmentContentType = firstAttachment["ContentType"] as? String,
           let firstAttachmentId = firstAttachment["AttachmentId"] as? String {
            attachmentName = firstAttachmentName
            contentType = firstAttachmentContentType
            attachmentId = firstAttachmentId
        } else {
            SDKLogger.logger.logError("Failed to access attachments")
            return nil
        }

        let message = Message(
            participant: participantRole,
            text: attachmentName!,
            contentType: contentType!,
            timeStamp: time,
            attachmentId: attachmentId,
            messageId: messageId,
            displayName: displayName,
            serializedContent: serializedContent
        )
        return message
    }
    
    func handleParticipantEvent(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let participantRole = innerJson["ParticipantRole"] as! String
        let time = innerJson["AbsoluteTime"] as! String
        let displayName = innerJson["DisplayName"] as! String
        let messageId = innerJson["Id"] as! String

        return Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
            messageId: messageId,
            displayName: displayName,
            participant: participantRole,
            eventDirection: .Common,
            serializedContent: serializedContent
        )
    }
    
    func handleTyping(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem {
        let participantRole = innerJson["ParticipantRole"] as! String
        let time = innerJson["AbsoluteTime"] as! String
        let displayName = innerJson["DisplayName"] as! String
        let messageId = innerJson["Id"] as! String
        let isFromPastSession = innerJson["IsFromPastSession"] as? Bool ?? false

        let event = Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
            messageId: messageId,
            displayName: displayName,
            participant: participantRole,
            eventDirection: .Common,
            serializedContent: serializedContent
        )

        if !isFromPastSession {
            // Current session event: Emit typing event with Event object
            eventPublisher.send(.typing(event))
        }

        return event
    }
    
    func handleChatEnded(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let time = innerJson["AbsoluteTime"] as! String
        let isFromPastSession = innerJson["IsFromPastSession"] as? Bool ?? false

        if !isFromPastSession {
            // Current session event: Reset state and update session
            resetHeartbeatManagers()
            eventPublisher.send(.chatEnded)
            ConnectionDetailsProvider.shared.setChatSessionState(isActive: false)
        }
        
        let messageId = innerJson["Id"] as! String
        return Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
            messageId: messageId,
            eventDirection: .Common,
            serializedContent: serializedContent)
    }
    
    func handleParticipantStateChange(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let contentType = innerJson["ContentType"] as? String ?? ""
        let participantRole = innerJson["ParticipantRole"] as! String
        let time = innerJson["AbsoluteTime"] as! String
        let displayName = innerJson["DisplayName"] as! String
        let messageId = innerJson["Id"] as! String
        let isFromPastSession = innerJson["IsFromPastSession"] as? Bool ?? false

        let event = Event(
            timeStamp: time,
            contentType: contentType,
            messageId: messageId,
            displayName: displayName,
            participant: participantRole,
            eventDirection: .Common,
            serializedContent: serializedContent
        )

        // Determine the event type based on ContentType and publish if current session
        if !isFromPastSession {
            let eventType: ChatEvent
            switch contentType {
            case ContentType.participantIdle.rawValue:
                eventType = .participantIdle(event)
            case ContentType.participantReturned.rawValue:
                eventType = .participantReturned(event)
            case ContentType.autoDisconnection.rawValue:
                eventType = .autoDisconnection(event)
            case ContentType.participantInvited.rawValue:
                eventType = .participantInvited(event)
            case ContentType.chatRehydrated.rawValue:
                eventType = .chatRehydrated(event)
            default:
                SDKLogger.logger.logError("Unknown participant state event type: \(contentType)")
                return event // Return the event even if we don't recognize the type
            }
            
            // Current session event: Emit the specific event type
            eventPublisher.send(eventType)
        }

        return event
    }
    
    
    func handleMetadata(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let messageMetadata = innerJson["MessageMetadata"] as! [String: Any]
        let messageId = messageMetadata["MessageId"] as! String
        let receipts = messageMetadata["Receipts"] as? [[String: Any]]
        var status: MessageStatus = .Delivered // Default status
        let time = innerJson["AbsoluteTime"] as! String
        let isFromPastSession = innerJson["IsFromPastSession"] as? Bool ?? false

        if let receipts = receipts {
            for receipt in receipts {
                if receipt["ReadTimestamp"] is String {
                    status = .Read
                    if !isFromPastSession {
                        triggerReceiptCallback(receipt: receipt, messageId: messageId, contentType: .messageRead, innerJson: innerJson, time: time)
                    }
                } else if receipt["DeliveredTimestamp"] is String {
                    if status != .Read { // Don't downgrade from Read to Delivered
                        status = .Delivered
                    }
                    if !isFromPastSession {
                        triggerReceiptCallback(receipt: receipt, messageId: messageId, contentType: .messageDelivered, innerJson: innerJson, time: time)
                    }
                }
            }
        }
        
        return Metadata(
            status: status,
            messageId: messageId,
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
            eventDirection: .Outgoing,
            serializedContent: serializedContent
        )
    }
    
    private func triggerReceiptCallback(receipt: [String: Any], messageId: String, contentType: ContentType, innerJson: [String: Any], time: String) {
        let timestampKey = contentType == .messageRead ? "ReadTimestamp" : "DeliveredTimestamp"
        let receiptTime = receipt[timestampKey] as? String ?? time
        
        // Extract participant ID - receipts use "RecipientParticipantId"
        let participantId = receipt["RecipientParticipantId"] as? String ?? "Unknown"
        
        let receiptEvent = Event(
            text: contentType == .messageRead ? "Message read" : "Message delivered",
            timeStamp: receiptTime,
            contentType: contentType.rawValue,
            messageId: messageId,
            displayName: nil, // Receipts don't have display names
            participant: participantId, // Store the actual participant ID
            eventDirection: .Incoming,
            serializedContent: [
                "receipt": receipt,
                "originalMessage": innerJson
            ]
        )
        
        if contentType == .messageRead {
            eventPublisher.send(.readReceipt(receiptEvent))
        } else {
            eventPublisher.send(.deliveredReceipt(receiptEvent))
        }
    }
    
}

