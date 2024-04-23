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
        setupEventCallbacks()
    }
    
    public func configure(with config: GlobalConfig) {
        AWSClient.shared.configure(with: config)
    }
    
    public func connect(chatDetails: ChatDetails) {
        self.chatService?.createChatSession(chatDetails: chatDetails) { [weak self] success, error in
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
        self.chatService?.disconnectChatSession { success, error in
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
    
    public func sendMessage(message: String) {
        self.chatService?.sendMessage(message: message) { success, error in
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
    
    public func sendEvent(event: ContentType, content: String) {
        self.chatService?.sendEvent(event: event, content: content) { success, error in
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
    
    private func setupEventCallbacks() {
        self.chatService?.onMessageReceived { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.append(message)
                self?.onMessageReceived?(message)
            }
        }
        self.chatService?.onConnected {
            DispatchQueue.main.async {
                self.isConnected = true
                self.onConnectionEstablished?()
            }
        }
        self.chatService?.onDisconnected {
            DispatchQueue.main.async {
                self.isConnected = false
                self.onConnectionBroken?()
            }
        }
        self.chatService?.onError { error in
            print("Error: \(error?.localizedDescription ?? "Unknown error")")
        }
        
    }
    
    // Further methods for sending messages, handling chat events, etc.
}
