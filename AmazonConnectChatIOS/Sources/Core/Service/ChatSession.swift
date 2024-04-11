//
//  ChatSession.swift
//  AmazonConnectChatIOS

import Foundation
import Combine

public protocol ChatSessionProtocol: ObservableObject, ChatEventHandlers {
    var isConnected: Bool { get }
    var messages: [Message] { get }
    func connect(chatDetails: ChatDetails)
    func disconnect()
}

public class ChatSession: ChatSessionProtocol {
    
    public static let shared = ChatSession()
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var messages: [Message] = []
    private var chatService: ChatServiceProtocol?
    
    // Event Handlers
    public var onConnectionEstablished: (() -> Void)?
    public var onConnectionBroken: (() -> Void)?
    public var onMessageReceived: ((Message) -> Void)?
    public var onChatEnded: (() -> Void)?
    
    init(chatService: ChatServiceProtocol = ChatService()) {
        self.chatService = chatService
    }
    
    public func configure(with config: GlobalConfig) {
        AWSClient.shared.configure(with: config)
        self.chatService = ChatService()
        // Additional configuration...
    }
    
    public func connect(chatDetails: ChatDetails) {
        chatService?.createChatSession(chatDetails: chatDetails) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isConnected = success
                if success {
                    print("Chat session successfully created.")
                    self?.onConnectionEstablished?()
                } else {
                    print("Error creating chat session: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    public func disconnect() {
        chatService?.disconnectChatSession { success, error in
            DispatchQueue.main.async {
                self.isConnected = !success
                if !success {
                    print("Error disconnecting chat session")
                } else {
                    self.onChatEnded?()
                }
            }
        }
    }
    
    
    // Example method to simulate receiving a new message
    func receiveMessage(message: String) {
    }
    
    // Further methods for sending messages, handling chat events, etc.
}
