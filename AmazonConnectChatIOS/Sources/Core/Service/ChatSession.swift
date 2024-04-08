//
//  ChatSession.swift
//  AmazonConnectChatIOS

import Foundation
import Combine

public protocol ChatSessionProtocol: ObservableObject {
    var isConnected: Bool { get }
    var messages: [Message] { get }
    func connect(chatDetails: ChatDetails)
}

public class ChatSession: ChatSessionProtocol {
    public static let shared = ChatSession()
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var messages: [Message] = []
    private var chatService: ChatServiceProtocol?
    
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
                } else {
                    print("Error creating chat session: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // Example method to simulate receiving a new message
    func receiveMessage(message: String) {
    }
    
    // Further methods for sending messages, handling chat events, etc.
}
