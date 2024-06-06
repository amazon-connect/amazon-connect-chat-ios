// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import Combine
import AWSConnectParticipant

/// Protocol defining the core functionalities of a chat session.
public protocol ChatSessionProtocol {
    func configure(config: GlobalConfig)
    func connect(chatDetails: ChatDetails, completion: @escaping (Result<Void, Error>) -> Void)
    func disconnect(completion: @escaping (Result<Void, Error>) -> Void)
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Result<Void, Error>) -> Void)
    func sendEvent(event: ContentType, content: String, completion: @escaping (Result<Void, Error>) -> Void)
    func sendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<TranscriptResponse, Error>) -> Void)
    func sendAttachment(file: URL, completion: @escaping (Result<Void, Error>) -> Void)
    func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL?, Error>) -> Void)
    func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL?, Error>) -> Void)
    
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
        cleanupSubscriptions()
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
                if !handleTranscriptList.isEmpty {
                    self?.onTranscriptUpdated?(handleTranscriptList)
                }
            }
        }
    }
    
    /// Re-establishes subscriptions to various chat-related events.
    private func reestablishSubscriptions() {
        setupEventSubscriptions()
    }
    
    /// Configures the chat service with global configuration.
    public func configure(config: GlobalConfig) {
        AWSClient.shared.configure(with: config)
    }
    
    /// Attempts to connect to a chat session with the given details.
    public func connect(chatDetails: ChatDetails, completion: @escaping (Result<Void, Error>) -> Void) {
        reestablishSubscriptions() // Re-establish subscriptions whenever a new chat session is initiated
        chatService.createChatSession(chatDetails: chatDetails) { success, error in
            DispatchQueue.main.async {
                if success {
                    SDKLogger.logger.logDebug("Chat session successfully created.")
                    completion(.success(())) // Call completion with success
                } else if let error = error {
                    SDKLogger.logger.logError("Error creating chat session: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    
    public func getTranscript(
        scanDirection: AWSConnectParticipantScanDirection? = .backward,
        sortOrder: AWSConnectParticipantSortKey? = .ascending,
        maxResults: NSNumber? = 15,
        nextToken: String? = nil,
        startPosition: AWSConnectParticipantStartPosition? = nil,
        completion: @escaping (Result<TranscriptResponse, Error>) -> Void
    ) {
        self.chatService.getTranscript(scanDirection: scanDirection, sortOrder: sortOrder, maxResults: maxResults, nextToken: nextToken, startPosition: startPosition) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    completion(.success(items))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Disconnects the current chat session.
    public func disconnect(completion: @escaping (Result<Void, Error>) -> Void) {
        chatService.disconnectChatSession { success, error in
            DispatchQueue.main.async {
                if success {
                    self.onChatEnded?()
                    self.cleanupSubscriptions()
                    completion(.success(()))
                } else if let error = error {
                    SDKLogger.logger.logError("Error disconnecting chat session: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Sends a message within the chat session.
    public func sendMessage(contentType: ContentType, message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        chatService.sendMessage(contentType: contentType, message: message) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    SDKLogger.logger.logError("Error sending message: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Sends an event within the chat session.
    public func sendEvent(event: ContentType, content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        chatService.sendEvent(event: event, content: content) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    SDKLogger.logger.logError("Error sending event: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Sends read receipt for a message.
    public func sendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        chatService.sendMessageReceipt(event: event, messageId: messageId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    completion(.success(()))
                case .failure(let error):
                    SDKLogger.logger.logError("Error sending message receipt: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Sends an attachment within the chat session.
    public func sendAttachment(file: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        chatService.sendAttachment(file: file) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    SDKLogger.logger.logError("Error sending attachment: \(error.localizedDescription )")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Downloads an attachment to the app's temporary directory given an attachment ID.
    public func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL?, Error>) -> Void) {
        chatService.downloadAttachment(attachmentId: attachmentId, filename: filename) { result in
            switch result {
            case .success(let localUrl):
                SDKLogger.logger.logDebug("File successfully downloaded to temporary directory")
                completion(.success(localUrl))
            case .failure(let error):
                SDKLogger.logger.logError("Failed to download attachment: \(error.localizedDescription )")
                completion(.failure(error))
            }
        }
    }
    
    /// Returns the download URL link for the given attachment ID
    public func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL?, Error>) -> Void) {
        chatService.getAttachmentDownloadUrl(attachmentId: attachmentId) { result in
            switch result {
            case .success(let localUrl):
                SDKLogger.logger.logDebug("Attachment download url successfully retrieved")
                completion(.success(localUrl))
            case .failure(let error):
                SDKLogger.logger.logError("Failed to download attachment \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    deinit {
        eventSubscription?.cancel()
        messageSubscription?.cancel()
        transcriptSubscription?.cancel()
    }
    
    private func cleanupSubscriptions() {
        eventSubscription?.cancel()
        messageSubscription?.cancel()
        transcriptSubscription?.cancel()
    }
}

