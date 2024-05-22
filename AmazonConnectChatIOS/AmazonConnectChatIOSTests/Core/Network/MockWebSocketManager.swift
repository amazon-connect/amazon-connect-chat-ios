////
////  MockWebSocketManager.swift
////  AmazonConnectChatIOSTests
////
////  Created by Mittal, Rajat on 5/18/24.
////
//
import Foundation
import Combine
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
}
