//
//  ChatEventHandlers.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/9/24.
//

import Foundation

public protocol ChatEventHandlers {
    var onConnectionEstablished: (() -> Void)? { get set }
    var onConnectionBroken: (() -> Void)? { get set }
    var onMessageReceived: ((Message) -> Void)? { get set }
    var onChatEnded: (() -> Void)? { get set }
    // Add more event handlers as needed
}
