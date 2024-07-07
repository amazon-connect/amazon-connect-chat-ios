// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import Combine
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockWebsocketManager: WebsocketManagerProtocol {
    
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptPublisher = PassthroughSubject<TranscriptItem, Never>()
    
    func connect(wsUrl: URL?) {
        // Simulate connection logic if needed
        SDKLogger.logger.logDebug("MockWebsocketManager: Connected to \(String(describing: wsUrl))")
    }
    
    func disconnect() {
        // Simulate disconnection logic if needed
        SDKLogger.logger.logDebug("MockWebsocketManager: Disconnected")
    }
    
    func formatAndProcessTranscriptItems(_ items: [AWSConnectParticipantItem]) -> [TranscriptItem] {
        // Mock implementation of format and process transcript items
        return items.map { item in
            return TranscriptItem(timeStamp: item.absoluteTime ?? "", contentType: item.contentType ?? "",id: item.identifier, serializedContent: ["content": item.content ?? ""])
        }
    }
    
}
