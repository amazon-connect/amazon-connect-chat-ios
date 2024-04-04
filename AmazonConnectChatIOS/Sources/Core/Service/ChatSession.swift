//
//  ChatSession.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation
import Combine

class ChatSession: ObservableObject {
    static let shared = ChatSession()
    
    @Published var isConnected: Bool = false
    @Published var messages: [String] = [] // Example message type, adjust as needed
    private var chatService: ChatService?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func configure(with config: GlobalConfig, chatDetails: ChatDetails) {
        AWSClient.shared.configure(with: config)
        self.chatService = ChatService()
        // Additional configuration...
    }
    
    func connect(chatDetails: ChatDetails) {
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
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }
    
    // Further methods for sending messages, handling chat events, etc.
}
