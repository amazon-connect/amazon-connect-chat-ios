//
//  ChatSession.swift
//  AmazonConnectChatIOS

import Foundation
import Combine
import AWSConnectParticipant

/// Protocol defining the core functionalities of a chat session.
public protocol ChatSessionProtocol {
    func configure(config: GlobalConfig)
    func connect(chatDetails: ChatDetails, onError: @escaping (Error?) -> Void)
    func disconnect(onError: @escaping (Error) -> Void)
    func sendMessage(contentType: ContentType, message: String, onError: @escaping (Error) -> Void)
    func sendEvent(event: ContentType, content: String, onError: @escaping (Error) -> Void)
    
    var onConnectionEstablished: (() -> Void)? { get set }
    var onConnectionBroken: (() -> Void)? { get set }
    var onMessageReceived: ((TranscriptItem) -> Void)? { get set }
    var onTranscriptUpdated: (([TranscriptItem]) -> Void)? { get set }
    var onChatEnded: (() -> Void)? { get set }
}

public class ChatSession: ChatSessionProtocol {
    public static let shared : ChatSessionProtocol = ChatSession()
    private var chatService: ChatServiceProtocol
    private var eventSubscription: AnyCancellable?
    private var messageSubscription: AnyCancellable?
    private var transcriptSubscription: AnyCancellable?
    
    public var onConnectionEstablished: (() -> Void)?
    public var onConnectionBroken: (() -> Void)?
    public var onMessageReceived: ((TranscriptItem) -> Void)?
    public var onTranscriptUpdated: (([TranscriptItem]) -> Void)?
    public var onChatEnded: (() -> Void)?
    
    /// Initializes a new chat session with a specified chat service.
    /// - Parameter chatService: The chat service to use for managing chat sessions.
    init(chatService: ChatServiceProtocol = ChatService()) {
        self.chatService = chatService
        setupEventSubscriptions()
    }
    
    /// Sets up subscriptions to various chat-related events.
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
        
        messageSubscription = chatService.subscribeToTranscriptItem  { [weak self] handleTranscriptItem in
            DispatchQueue.main.async {
                self?.onMessageReceived?(handleTranscriptItem)
            }
        }
        
        transcriptSubscription = chatService.subscribeToTranscriptList { [weak self] handleTranscriptList in
            DispatchQueue.main.async {
                self?.onTranscriptUpdated?(handleTranscriptList)
            }
        }
    }
    
    /// Configures the chat service with global configuration.
    public func configure(config: GlobalConfig) {
        AWSClient.shared.configure(with: config)
    }
    
    /// Attempts to connect to a chat session with the given details.
    public func connect(chatDetails: ChatDetails, onError: @escaping (Error?) -> Void) {
        chatService.createChatSession(chatDetails: chatDetails) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    SDKLogger.logger.logDebug("Chat session successfully created.")
                } else if let error = error {
                    print()
                    SDKLogger.logger.logError("Error creating chat session: \(error.localizedDescription )")
                    onError(error)
                }
            }
        }
    }
    
    public func getTranscript(
        scanDirection: AWSConnectParticipantScanDirection? = nil,
        sortOrder: AWSConnectParticipantSortKey? = nil,
        maxResults: NSNumber? = nil,
        nextToken: String? = nil,
        startPosition: AWSConnectParticipantStartPosition? = nil
    ) {
        self.chatService.getTranscript(scanDirection: scanDirection, sortOrder: sortOrder, maxResults: maxResults, nextToken: nextToken, startPosition: startPosition) { result in
            switch result {
            case .success(let items):
                print("Get transcript response: \(items)")
            case .failure(let error):
                print("Get transcript failure: \(error)")
            }
        }
    }
    
    /// Disconnects the current chat session.
    public func disconnect(onError: @escaping (Error) -> Void) {
        chatService.disconnectChatSession { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.onChatEnded?()
                    self?.cleanupSubscriptions()
                } else if let error = error {
                    SDKLogger.logger.logError("Error disconnecting chat session: \(error.localizedDescription )")
                    onError(error)
                }
            }
        }
    }
    
    /// Sends a message within the chat session.
    public func sendMessage(contentType: ContentType, message: String, onError: @escaping (Error) -> Void) {
        chatService.sendMessage(contentType: contentType, message: message) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    SDKLogger.logger.logError("Error sending message: \(error.localizedDescription )")
                    onError(error)
                }
            }
        }
    }
    
    /// Sends an event within the chat session.
    public func sendEvent(event: ContentType, content: String, onError: @escaping (Error) -> Void) {
        chatService.sendEvent(event: event, content: content) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    SDKLogger.logger.logError("Error sending event: \(error.localizedDescription )")
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

