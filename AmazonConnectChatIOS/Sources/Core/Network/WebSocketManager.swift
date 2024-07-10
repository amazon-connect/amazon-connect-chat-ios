// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import AWSConnectParticipant
import Combine

enum EventTypes {
    static let subscribe = "{\"topic\": \"aws/subscribe\", \"content\": {\"topics\": [\"aws/chat\"]}})"
    static let heartbeat = "{\"topic\": \"aws/heartbeat\"}"
    static let deepHeartbeat = "{\"topic\": \"aws/ping\"}"
}

protocol WebsocketManagerProtocol {
    var eventPublisher: PassthroughSubject<ChatEvent, Never> { get }
    var transcriptPublisher: PassthroughSubject<TranscriptItem, Never> { get }
    func connect(wsUrl: URL?)
    func disconnect()
    func formatAndProcessTranscriptItems(_ transcriptItems: [AWSConnectParticipantItem]) -> [TranscriptItem]
}

class WebsocketManager: NSObject, WebsocketManagerProtocol {
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptPublisher = PassthroughSubject<TranscriptItem, Never>()
    
    private var websocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var heartbeatManager: HeartbeatManager?
    private var deepHeartbeatManager: HeartbeatManager?
    private var wsUrl: URL?
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
    }
    
    func connect(wsUrl: URL? = nil) {
        disconnect() // Ensure previous WebSocket tasks are properly closed
        
        if let wsTask = self.websocketTask {
            wsTask.cancel(with: .goingAway, reason: nil)
        }
        if let nonEmptyWsUrl = wsUrl {
            // self.hasActiveReconnection = false
            self.wsUrl = nonEmptyWsUrl
        }
        if let webSocketUrl = self.wsUrl {
            self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
            self.websocketTask = self.session?.webSocketTask(with: webSocketUrl)
            websocketTask?.resume()
            receiveMessage()
        } else {
            print("No WebSocketURL found")
            return
        }
    }
    
    func sendWebSocketMessage(string message: String) {
        let messageToSend = URLSessionWebSocketTask.Message.string(message)
        websocketTask?.send(messageToSend) { error in
            if let error = error {
                print("Failed to send message: \(error)")
            } else {
                print("Message sent: \(message)")
            }
        }
    }
    
    private func receiveMessage() {
        websocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Failed to receive message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text in receiveMessage()")
                    self?.handleWebsocketTextEvent(text: text)
                case .data(let data):
                    print("Received data from websocket")
                @unknown default:
                    print("Received an unknown message type, which is not handled.")
                }
                self?.receiveMessage()
            }
        }
    }
    
    // MARK: - WebSocketDelegate
    // Background / Foreground Domain=NSPOSIXErrorDomain Code=53 "Software caused connection abort"
    // Network disconnect = Domain=NSURLErrorDomain Code=-1005 "The network connection was lost."
    func handleError(_ error: Error?) {
        if let nsError = error as? NSError {
            switch (nsError.domain) {
            case NSPOSIXErrorDomain:
                if (nsError.code == WebSocketErrorCodes.SOFTWARE_ABORT.rawValue) {
                    NotificationCenter.default.post(name: .requestNewWsUrl, object: nil)
                }
                break
            case NSURLErrorDomain:
                if (nsError.code == WebSocketErrorCodes.NETWORK_DISCONNECTED.rawValue) {
                    SDKLogger.logger.logDebug("WebSocket disconnected due to lost network connection")
                } else if (nsError.code == WebSocketErrorCodes.BAD_SERVER_RESPONSE.rawValue) {
                    NotificationCenter.default.post(name: .requestNewWsUrl, object: nil)
                }
                break
            default:
                SDKLogger.logger.logDebug("DEBUG - DOMAIN: \(nsError.domain)")
                SDKLogger.logger.logDebug("DEBUG - CODE: \(nsError.code)")
                SDKLogger.logger.logDebug("DEBUG - DESCRIPTION: \(nsError.localizedDescription)")
            }
        }
        
        if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
        self.onError?(error)
    }
    
    func disconnect() {
        websocketTask?.cancel(with: .goingAway, reason: nil)
        websocketTask = nil
    }
    
    func addNetworkNotificationObserver() {
        NotificationCenter.default.addObserver(forName: .networkConnected, object: nil, queue: .main) { [weak self] _ in
            if (ChatSession.shared.isChatSessionActive()) {
                NotificationCenter.default.post(name: .requestNewWsUrl, object: nil)
            }
        }
    }
    
    func handleWebsocketTextEvent(text: String) {
        guard let jsonData = text.data(using: .utf8) else { return }
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                processJsonContent(json)
            }
        } catch {
            print("Error parsing JSON from WebSocket: \(error)")
        }
    }
    
    func processJsonContent(_ json: [String: Any]) {
        if let topic = json["topic"] as? String {
            switch topic {
            case "aws/ping":
                if (json["statusCode"] as? Int == 200 && json["statusContent"] as? String == "OK") {
                    self.deepHeartbeatManager?.heartbeatReceived()
                } else {
                    print("Deep heartbeat failed. Status: \(json["statusCode"] ?? "nil"), StatusContent: \(json["statusContent"] ?? "nil")")
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
            transcriptPublisher.send(item)
        }
    }
    
    func processJsonContentAndGetItem(_ json: [String: Any]) -> TranscriptItem? {
        let content = json["content"] as? String
        
        if let stringContent = content,
           let innerJson = try? JSONSerialization.jsonObject(with: Data(stringContent.utf8), options: []) as? [String: Any] {
            guard let typeString = innerJson["Type"] as? String, let type = WebSocketMessageType(rawValue: typeString) else {
                print("Unknown websocket message type: \(String(describing: innerJson["Type"]))")
                return nil
            }
            let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!
            switch type {
            case .message:
                return self.handleMessage(innerJson, json)
            case .event:
                guard let eventTypeString = innerJson["ContentType"] as? String, let eventType = ContentType(rawValue: eventTypeString) else {
                    print("Unknown event type \(String(describing: innerJson["ContentType"]))")
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
                default:
                    print("Unknown event: \(String(describing: eventType))")
                }
            case .attachment:
                return handleAttachment(innerJson, json)
            case .messageMetadata:
                return handleMetadata(innerJson, json)
            }
            
            return nil
        }
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
            print("Heartbeat missed")
        } else {
            print("Device is not connected to the internet")
        }
    }
    
    func onDeepHeartbeatMissed() {
        if !ChatSession.shared.isChatSessionActive() {
            return
        }
        if NetworkConnectionManager.shared.checkConnectivity() {
            print("Deep heartbeat missed")
        } else {
            print("Device is not connected to the internet")
        }
        self.eventPublisher.send(.connectionBroken)
    }
}


// MARK: - URLSessionWebSocketDelegate

extension WebsocketManager: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Websocket connection successfully established")
        self.onConnected?()
        self.eventPublisher.send(.connectionEstablished)
        self.sendWebSocketMessage(string: EventTypes.subscribe)
        self.startHeartbeats()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.onDisconnected?()
        print("WebSocket connection closed")
    }
    
    // Foregrounded
    //  - see if websocket is connected, if it isn't we try reconnecting
    //  - Call get transcript
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("WebSocket connection completed with error.")
        self.onDisconnected?()
        if error != nil {
            handleError(error)
        }

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
                "Attachments": attachmentsArray
            ]
            
            // Serialize the dictionary to JSON string
            guard let messageContentData = try? JSONSerialization.data(withJSONObject: messageContentDict, options: []),
                  let messageContentString = String(data: messageContentData, encoding: .utf8) else {
                print("Failed to serialize message content to JSON string")
                return nil
            }
            
            // Wrap the JSON string
            let wrappedMessageString = "{\"content\":\"\(messageContentString.replacingOccurrences(of: "\"", with: "\\\""))\"}"
            
            // Deserialize back to JSON object
            if let jsonData = wrappedMessageString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                // Process the JSON content and return a TranscriptItem
                let transcriptItem = self.processJsonContentAndGetItem(json)
                if let validItem = transcriptItem {
                    transcriptPublisher.send(validItem)
                }

                return transcriptItem
            }
            
            return nil
        }
    }

    
    // MARK: - Handle Events
    func handleMessage(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let participantRole = innerJson["ParticipantRole"] as! String
        let messageId = innerJson["Id"] as! String
        var messageText = innerJson["Content"] as! String
        let displayName = innerJson["DisplayName"] as! String
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!

        // Workaround for Attributed string to enable newline
        messageText = messageText.replacingOccurrences(of: "\n", with: "\\\n")
        
        return Message(
            participant: participantRole,
            text: messageText,
            contentType: innerJson["ContentType"] as! String,
            timeStamp: time,
            messageId: messageId,
            displayName: displayName,
            serializedContent: serializedContent
        )
    }
    
    func handleAttachment(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem?  {
        let participantRole = innerJson["ParticipantRole"] as! String
        let messageId = innerJson["Id"] as! String
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!
        
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
            print("Failed to access attachments")
            return nil
        }

        let message = Message(
            participant: participantRole,
            text: attachmentName!,
            contentType: contentType!,
            timeStamp: time,
            attachmentId: attachmentId,
            messageId: messageId,
            serializedContent: serializedContent
        )
        return message
    }
    
    func handleParticipantEvent(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let participantRole = innerJson["ParticipantRole"] as! String
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!
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
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!
        let displayName = innerJson["DisplayName"] as! String
        let messageId = innerJson["Id"] as! String

        return Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
            messageId: messageId,
            participant: participantRole,
            serializedContent: serializedContent
        )
    }
    
    func handleChatEnded(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!
        self.eventPublisher.send(.chatEnded)
        let messageId = innerJson["Id"] as! String
        resetHeartbeatManagers()

        return Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
            messageId: messageId,
            eventDirection: .Common,
            serializedContent: serializedContent)
    }
    
    func handleMetadata(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let messageMetadata = innerJson["MessageMetadata"] as! [String: Any]
        let messageId = messageMetadata["MessageId"] as! String
        let receipts = messageMetadata["Receipts"] as? [[String: Any]]
        var status: MessageStatus = .Delivered // Default status
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!

        if let receipts = receipts {
            for receipt in receipts {
                if receipt["ReadTimestamp"] is String {
                    status = .Read
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
    
}

