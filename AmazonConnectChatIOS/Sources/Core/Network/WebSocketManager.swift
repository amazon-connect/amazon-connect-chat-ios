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
    var isConnected = false
    private var heartbeatManager: HeartbeatManager?
    private var deepHeartbeatManager: HeartbeatManager?
    private var hasActiveReconnection = false
    private var pendingNetworkReconnection = false
    private var wsUrl: URL?
    private var intentionalDisconnect = false
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
        self.intentionalDisconnect = false
        disconnect() // Ensure previous WebSocket tasks are properly closed
        
        if let wsTask = self.websocketTask {
            wsTask.cancel(with: .goingAway, reason: nil)
        }
        if let nonEmptyWsUrl = wsUrl {
            self.hasActiveReconnection = false
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
    
    func handleError(_ error: Error?) {
        if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
        self.onError?(error)
    }
    
    func disconnect() {
        self.intentionalDisconnect = true
        websocketTask?.cancel(with: .goingAway, reason: nil)
        websocketTask = nil
    }
    
    func addNetworkNotificationObserver() {
        NotificationCenter.default.addObserver(forName: .networkConnected, object: nil, queue: .main) { [weak self] _ in
            if (self?.pendingNetworkReconnection == true) {
                self?.pendingNetworkReconnection = false
                self?.retryConnection()
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
                    return handleParticipantJoined(innerJson, json)
                case .left:
                    // Handle participant left event
                    return handleParticipantLeft(innerJson, json)
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
    
    func retryConnection() {
        if !self.hasActiveReconnection {
            self.hasActiveReconnection = true
            var numAttempts = 0.0
            var numOfflineChecks = 0.0
            var timer: Timer?
            
            func retry() {
                if self.wsUrl == nil {
                    return
                }
                timer?.invalidate()
                if numOfflineChecks < 5 {
                    if numAttempts < 5 {
                        DispatchQueue.main.async {
                            timer = Timer.scheduledTimer(withTimeInterval: self.getRetryDelay(numAttempts: max(numAttempts, numOfflineChecks)), repeats: false) { _ in
                                if NetworkConnectionManager.shared.checkConnectivity() {
                                    numOfflineChecks = 0
                                    if self.isConnected {
                                        print("Connected successfully on attempt \(numAttempts)")
                                        timer?.invalidate()
                                        self.hasActiveReconnection = false
                                        numAttempts = 0.0
                                    } else {
                                        print("Attempting websocket re-connect... attempt \(numAttempts)")
                                        self.connect()
                                        numAttempts += 1
                                        retry()
                                    }
                                } else {
                                    print("Device is not connected to the internet, retrying... attempt \(numOfflineChecks)")
                                    numOfflineChecks += 1
                                    numAttempts = 0
                                    retry()
                                }
                            }
                        }
                    } else {
                        print("Retry connection failed after \(numAttempts) attempts. Please re-start chat session.")
                        self.hasActiveReconnection = false
                    }
                } else {
                    print("Network connection has been lost. Please restore your network connection to try again.")
                    self.pendingNetworkReconnection = true
                    self.hasActiveReconnection = false
                }
            }
            retry()
        }
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
        if !self.isConnected {
            return
        }
        if NetworkConnectionManager.shared.checkConnectivity() {
            print("Heartbeat missed")
        } else {
            print("Device is not connected to the internet")
        }
        retryConnection()
    }
    
    func onDeepHeartbeatMissed() {
        if !self.isConnected {
            return
        }
        if NetworkConnectionManager.shared.checkConnectivity() {
            print("Deep heartbeat missed")
        } else {
            print("Device is not connected to the internet")
        }
        self.eventPublisher.send(.connectionBroken)
        retryConnection()
    }
}


// MARK: - URLSessionWebSocketDelegate

extension WebsocketManager: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Websocket connection successfully established")
        self.onConnected?()
        self.isConnected = true
        self.eventPublisher.send(.connectionEstablished)
        self.sendWebSocketMessage(string: EventTypes.subscribe)
        self.startHeartbeats()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.onDisconnected?()
        self.isConnected = false
        print("WebSocket connection closed")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("WebSocket connection completed with error.")
        self.onDisconnected?()
        self.isConnected = false
        if error != nil {
            handleError(error)
        }
        guard let response = task.response as? HTTPURLResponse else {
            print("Failed to parse HTTPURLResponse")
            return
        }
        if response.statusCode == 403 {
            NotificationCenter.default.post(name: .requestNewWsUrl, object: nil)
            self.wsUrl = nil
        }
        self.intentionalDisconnect = false
    }
}


// MARK: - Formatting extension

extension WebsocketManager {
    func formatAndProcessTranscriptItems(_ transcriptItems: [AWSConnectParticipantItem]) -> [TranscriptItem] {
        return transcriptItems.compactMap { item in
            // Create a dictionary with the necessary fields
            let participantRole = CommonUtils().convertParticipantRoleToString(item.participantRole.rawValue)
            let messageContentDict: [String: Any] = [
                "Id": item.identifier ?? "",
                "ParticipantRole": "\(participantRole)",
                "AbsoluteTime": item.absoluteTime ?? "",
                "ContentType": item.contentType ?? "",
                "Content": item.content ?? "",
                "Type": CommonUtils().convertParticipantTypeToString(item.types.rawValue),
                "DisplayName": item.displayName ?? ""
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
                return processJsonContentAndGetItem(json)
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
            messageID: messageId,
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
            messageID: messageId,
            serializedContent: serializedContent
        )
        return message
    }
    
    func handleParticipantJoined(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let participantRole = innerJson["ParticipantRole"] as! String
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!
        let displayName = innerJson["DisplayName"] as! String

        return Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
            displayName: displayName,
            participant: participantRole,
            eventDirection: .Common,
            serializedContent: serializedContent
        )
    }
    
    func handleParticipantLeft(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let participantRole = innerJson["ParticipantRole"] as! String
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!
        let displayName = innerJson["DisplayName"] as! String

        return Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
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

        return Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
            participant: participantRole,
            serializedContent: serializedContent
        )
    }
    
    func handleChatEnded(_ innerJson: [String: Any], _ serializedContent: [String: Any]) -> TranscriptItem? {
        let time = CommonUtils().formatTime(innerJson["AbsoluteTime"] as! String)!

        return Event(
            timeStamp: time,
            contentType: innerJson["ContentType"] as! String,
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

