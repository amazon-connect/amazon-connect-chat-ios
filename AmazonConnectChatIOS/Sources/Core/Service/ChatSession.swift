// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import Combine
import AWSConnectParticipant

/// Protocol defining the core functionalities of a chat session.
public protocol ChatSessionProtocol {
    /// Configures the chat service with global configuration.
    /// - Parameter config: The global configuration to use.
    func configure(config: GlobalConfig)
    
    /// Attempts to connect to a chat session with the given details.
    /// - Parameters:
    ///   - chatDetails: The details of the chat session to connect to.
    ///   - completion: The completion handler to call when the connect operation is complete.
    func connect(chatDetails: ChatDetails, completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Disconnects the current chat session.
    /// - Parameter completion: The completion handler to call when the disconnect operation is complete.
    func disconnect(completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Sends a message within the chat session.
    /// - Parameters:
    ///   - contentType: The type of the message content.
    ///   - message: The message to send.
    ///   - completion: The completion handler to call when the send operation is complete.
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Sends an event within the chat session.
    /// - Parameters:
    ///   - event: The type of the event content.
    ///   - content: The event content to send.
    ///   - completion: The completion handler to call when the send operation is complete.
    func sendEvent(event: ContentType, content: String, completion: @escaping (Result<Void, Error>) -> Void)

    /// Sends read receipt for a message.
    /// - Parameters:
    ///   - event: The type of the event content (default is .messageRead).
    ///   - messageId: The ID of the message to acknowledge.
    ///   - completion: The completion handler to call when the send operation is complete.
    func sendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<Void, Error>) -> Void)

    /// Retrieves the chat transcript.
    /// - Parameters:
    ///   - scanDirection: The direction to scan the transcript.
    ///   - sortOrder: The order to sort the transcript.
    ///   - maxResults: The maximum number of results to retrieve.
    ///   - nextToken: The token for the next set of results.
    ///   - startPosition: The start position for the transcript.
    ///   - completion: The completion handler to call when the transcript retrieval is complete.
    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<TranscriptResponse, Error>) -> Void)
    
    /// Sends an attachment within the chat session.
    /// - Parameters:
    ///   - file: The URL of the file to attach.
    ///   - completion: The completion handler to call when the send operation is complete.
    func sendAttachment(file: URL, completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Downloads an attachment to the app's temporary directory given an attachment ID.
    /// - Parameters:
    ///   - attachmentId: The ID of the attachment to download.
    ///   - filename: The name of the file to save the attachment as.
    ///   - completion: The completion handler to call when the download operation is complete.
    func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void)
    
    /// Returns the download URL link for the given attachment ID.
    /// - Parameters:
    ///   - attachmentId: The ID of the attachment.
    ///   - completion: The completion handler to call when the URL retrieval is complete.
    func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL, Error>) -> Void)
    
    var onConnectionEstablished: (() -> Void)? { get set }
    var onConnectionBroken: (() -> Void)? { get set }
    var onMessageReceived: ((TranscriptItem) -> Void)? { get set }
    var onTranscriptUpdated: (([TranscriptItem]) -> Void)? { get set }
    var onChatEnded: (() -> Void)? { get set }
}

public class ChatSession: ChatSessionProtocol {
    public static let shared : ChatSessionProtocol = ChatSession()
    var isChatSessionActive: Bool = false
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
                    self?.isChatSessionActive = true
                    self?.onConnectionEstablished?()
                case .connectionBroken:
                    self?.onConnectionBroken?()
                case .chatEnded:
                    if (self != nil && self?.isChatSessionActive == true) {
                        self?.isChatSessionActive = false
                        self?.onChatEnded?()
                    }
                default:
                    break
                }
            }
        }
        
        messageSubscription = chatService.subscribeToTranscriptItem { [weak self] transcriptItem in
            DispatchQueue.main.async {
                self?.onMessageReceived?(transcriptItem)
            }
        }
        
        transcriptSubscription = chatService.subscribeToTranscriptList { [weak self] transcriptList in
            DispatchQueue.main.async {
                if !transcriptList.isEmpty {
                    self?.onTranscriptUpdated?(transcriptList)
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
    
    /// Connects to a chat session with the given details.
    public func connect(chatDetails: ChatDetails, completion: @escaping (Result<Void, Error>) -> Void) {
        reestablishSubscriptions() // Re-establish subscriptions whenever a new chat session is initiated
        chatService.createChatSession(chatDetails: chatDetails) { [weak self] success, error in
            self?.handleCompletion(success: success, error: error, completion: completion)
        }
    }
    
    /// Retrieves the chat transcript.
    public func getTranscript(
        scanDirection: AWSConnectParticipantScanDirection? = .backward,
        sortOrder: AWSConnectParticipantSortKey? = .ascending,
        maxResults: NSNumber? = 15,
        nextToken: String? = nil,
        startPosition: AWSConnectParticipantStartPosition? = nil,
        completion: @escaping (Result<TranscriptResponse, Error>) -> Void
    ) {
        chatService.getTranscript(scanDirection: scanDirection, sortOrder: sortOrder, maxResults: maxResults, nextToken: nextToken, startPosition: startPosition) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Disconnects the current chat session.
    public func disconnect(completion: @escaping (Result<Void, Error>) -> Void) {
        if (!self.isChatSessionActive) {
            self.cleanupSubscriptions()
            return
        }
      
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
        chatService.sendMessage(contentType: contentType, message: message) { [weak self] success, error in
            self?.handleCompletion(success: success, error: error, completion: completion)
        }
    }
    
    /// Sends an event within the chat session.
    public func sendEvent(event: ContentType, content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        chatService.sendEvent(event: event, content: content) { [weak self] success, error in
            self?.handleCompletion(success: success, error: error, completion: completion)
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
        chatService.sendAttachment(file: file) { [weak self] success, error in
            self?.handleCompletion(success: success, error: error, completion: completion)
        }
    }
    
    /// Downloads an attachment to the app's temporary directory.
    public func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        chatService.downloadAttachment(attachmentId: attachmentId, filename: filename) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Returns the download URL link for the given attachment ID.
    public func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        chatService.getAttachmentDownloadUrl(attachmentId: attachmentId) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Cleans up subscriptions when the chat session is deinitialized.
    deinit {
        cleanupSubscriptions()
    }
    
    /// Cancels all active subscriptions.
    private func cleanupSubscriptions() {
        eventSubscription?.cancel()
        messageSubscription?.cancel()
        transcriptSubscription?.cancel()
    }
    
    /// Handles the completion of a service call.
    private func handleCompletion(success: Bool, error: Error?, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async {
            if success {
                completion(.success(()))
            } else if let error = error {
                SDKLogger.logger.logError("Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
