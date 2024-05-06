//
//  ChatSession.swift
//  AmazonConnectChatIOS

import Foundation
import Combine

public protocol ChatSessionProtocol {
    func configure(config: GlobalConfig)
    func connect(chatDetails: ChatDetails, onError: @escaping (Error?) -> Void)
    func disconnect(onError: @escaping (Error) -> Void)
    func sendMessage(contentType: ContentType, message: String, onError: @escaping (Error) -> Void)
    func sendEvent(event: ContentType, content: String, onError: @escaping (Error) -> Void)
    
    var onConnectionEstablished: (() -> Void)? { get set }
    var onConnectionBroken: (() -> Void)? { get set }
    var onMessageReceived: ((Message) -> Void)? { get set }
    var onChatEnded: (() -> Void)? { get set }
}

public class ChatSession: ChatSessionProtocol {
    public static let shared : ChatSessionProtocol = ChatSession()
    private var chatService: ChatServiceProtocol
    private var eventSubscription: AnyCancellable?
    private var messageSubscription: AnyCancellable?
    
    public var onConnectionEstablished: (() -> Void)?
    public var onConnectionBroken: (() -> Void)?
    public var onMessageReceived: ((Message) -> Void)?
    public var onChatEnded: (() -> Void)?
    
    init(chatService: ChatServiceProtocol = ChatService()) {
        self.chatService = chatService
        setupEventSubscriptions()
    }
    
    private func setupEventSubscriptions() {
        eventSubscription = chatService.subscribeToEvents { [weak self] event in
            DispatchQueue.main.async {
                switch event {
                case .connectionEstablished:
                    self?.onConnectionEstablished?()
                case .connectionBroken:
                    self?.onConnectionBroken?()
                default:
                    break
                }
            }
        }
        
        messageSubscription = chatService.subscribeToMessages { [weak self] message in
            DispatchQueue.main.async {
                self?.onMessageReceived?(message)
            }
        }
    }
    
    public func configure(config: GlobalConfig) {
        AWSClient.shared.configure(with: config)
    }
    
    public func connect(chatDetails: ChatDetails, onError: @escaping (Error?) -> Void) {
        chatService.createChatSession(chatDetails: chatDetails) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("Chat session successfully created.")
                } else if let error = error {
                    print("Error creating chat session: \(error.localizedDescription )")
                    onError(error)
                }
            }
        }
    }
    
    
    public func disconnect(onError: @escaping (Error) -> Void) {
        chatService.disconnectChatSession { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.onChatEnded?()
                    self?.cleanupSubscriptions()
                } else if let error = error {
                    print("Error disconnecting chat session: \(error.localizedDescription )")
                    onError(error)
                }
            }
        }
    }
    
    public func sendMessage(contentType: ContentType, message: String, onError: @escaping (Error) -> Void) {
        chatService.sendMessage(contentType: contentType, message: message) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error sending message: \(error.localizedDescription )")
                    onError(error)
                }
            }
        }
    }
    
    public func sendEvent(event: ContentType, content: String, onError: @escaping (Error) -> Void) {
        chatService.sendEvent(event: event, content: content) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error sending event: \(error.localizedDescription )")
                }
            }
        }
    }
    
    deinit {
        eventSubscription?.cancel()
        messageSubscription?.cancel()
    }
    
    
    private func cleanupSubscriptions() {
        eventSubscription?.cancel()
        messageSubscription?.cancel()
    }
}

