// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Combine
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockWebsocketManager: WebsocketManagerProtocol {
    var mockConnectionStatus = false
    var wsUrl: URL = URL(string: "about:blank")!
    
    init(wsUrl: URL = URL(string: "about:blank")!) {
        self.wsUrl = wsUrl
        self.connect(wsUrl: self.wsUrl)
    }
    
    func suspendWebSocketConnection() {
        // Simulate suspension logic if needed
        SDKLogger.logger.logDebug("MockWebsocketManager: Suspended WebSocket Connection")
        self.mockConnectionStatus = false
    }
    
    func resumeWebSocketConnection() {
        // Simulate resume logic if needed
        SDKLogger.logger.logDebug("MockWebsocketManager: Resume WebSocket Connection")
        self.mockConnectionStatus = true
    }
    
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptPublisher = PassthroughSubject<TranscriptItem, Never>()
    
    func connect(wsUrl: URL?,isReconnect: Bool? = false) {
        // Simulate connection logic if needed
        SDKLogger.logger.logDebug("MockWebsocketManager: Connected to \(String(describing: wsUrl))")
        self.mockConnectionStatus = true
    }
    
    func disconnect(reason: String?) {
        // Simulate disconnection logic if needed
        SDKLogger.logger.logDebug("MockWebsocketManager: Disconnected")
        self.mockConnectionStatus = false
    }
    
    func formatAndProcessTranscriptItems(_ items: [AWSConnectParticipantItem]) -> [TranscriptItem] {
        // Mock implementation of format and process transcript items
        return items.map { item in
            return TranscriptItem(timeStamp: item.absoluteTime ?? "", contentType: item.contentType ?? "", id: item.identifier, serializedContent: ["content": item.content ?? ""])
        }
    }
    
}
