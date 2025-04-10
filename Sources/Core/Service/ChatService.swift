// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Combine
import AWSConnectParticipant
import UniformTypeIdentifiers

protocol ChatServiceProtocol {
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void)
    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void)
    func suspendWebSocketConnection() -> Void
    func resumeWebSocketConnection() -> Void
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void)
    func resendFailedMessage(messageId: String, completion: @escaping (Bool, Error?) -> Void)
    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void)
    func sendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func sendPendingMessageReceipts(pendingMessageReceipts: PendingMessageReceipts, completion: @escaping (Result<MessageReceiptType, Error>) -> Void)
    func sendAttachment(file: URL, completion: @escaping (Bool, Error?) -> Void)
    func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void)
    func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL, Error>) -> Void)
    func subscribeToEvents(handleEvent: @escaping (ChatEvent) -> Void) -> AnyCancellable
    func subscribeToTranscriptItem(handleTranscriptItem: @escaping (TranscriptItem) -> Void) -> AnyCancellable
    func subscribeToTranscriptList(handleTranscriptList: @escaping ([TranscriptItem]) -> Void) -> AnyCancellable
    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<TranscriptResponse, Error>) -> Void)
    func configure(config: GlobalConfig)
    func getConnectionDetailsProvider() -> ConnectionDetailsProviderProtocol
    func reset() -> Void
}

class ChatService : ChatServiceProtocol {
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptItemPublisher = PassthroughSubject<TranscriptItem, Never>()
    var transcriptListPublisher = CurrentValueSubject<[TranscriptItem], Never>([])
    var urlSession = URLSession(configuration: .default)
    var apiClient: APIClientProtocol = APIClient.shared
    var messageReceiptsManager: MessageReceiptsManagerProtocol?
    var websocketManager: WebsocketManagerProtocol?
    var internalTranscript: [TranscriptItem] = []
    private var eventCancellables = Set<AnyCancellable>()
    private var transcriptItemCancellables = Set<AnyCancellable>()
    private var transcriptListCancellables = Set<AnyCancellable>()
    private let connectionDetailsProvider: ConnectionDetailsProviderProtocol
    private var awsClient: AWSClientProtocol
    private var websocketManagerFactory: (URL) -> WebsocketManagerProtocol
    private var throttleTypingEvent: Bool = false
    private var throttleTypingEventTimer: Timer?
    private var transcriptItemSet = Set<String>()
    private var typingIndicatorTimer: Timer?
    // Dictionary to map attachment IDs to temporary message IDs
    private var attachmentIdToTempMessageIdMap: [String: String] = [:]
    private var transcriptDict: [String: TranscriptItem] = [:]
    private var tempMessageIdToFileUrl: [String: URL] = [:]
    
    
    init(awsClient: AWSClientProtocol = AWSClient.shared,
        connectionDetailsProvider: ConnectionDetailsProviderProtocol = ConnectionDetailsProvider.shared,
        websocketManagerFactory: @escaping (URL) -> WebsocketManagerProtocol = { WebsocketManager(wsUrl: $0) }) {
        self.awsClient = awsClient
        self.connectionDetailsProvider = connectionDetailsProvider
        self.websocketManagerFactory = websocketManagerFactory
        self.messageReceiptsManager = MessageReceiptsManager()
        self.registerNotificationListeners()
    }

    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
        self.connectionDetailsProvider.updateChatDetails(newDetails: chatDetails)
        awsClient.createParticipantConnection(participantToken: chatDetails.participantToken) { result in
            switch result {
            case .success(let connectionDetails):
                self.connectionDetailsProvider.updateConnectionDetails(newDetails: connectionDetails)
                if let wsUrl = URL(string: connectionDetails.websocketUrl ?? "") {
                    self.setupWebSocket(url: wsUrl)
                }
                MetricsClient.shared.triggerCountMetric(metricName: .CreateParticipantConnection)
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    private func setupWebSocket(url: URL) {
        self.websocketManager = websocketManagerFactory(url)
        
        self.websocketManager?.eventPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] event in
                if (event == .chatEnded) {
                    self?.messageReceiptsManager?.invalidateTimer()
                } else if (event == .connectionEstablished) {
                    ConnectionDetailsProvider.shared.setChatSessionState(isActive: true)
                    self?.getTranscript() {_ in }
                }
                if (event == .connectionReEstablished){
                    self?.fetchReconnectedTranscript()
                }
                self?.eventPublisher.send(event)
            })
            .store(in: &eventCancellables)
        
        self.websocketManager?.transcriptPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] transcriptItem in
                self?.updateTranscriptDict(with: transcriptItem)
            })
            .store(in: &transcriptListCancellables)
    }
    
    func subscribeToEvents(handleEvent: @escaping (ChatEvent) -> Void) -> AnyCancellable {
        let subscription = eventPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { event in
                handleEvent(event)
            })
        eventCancellables.insert(subscription)
        return subscription
    }
    
    func subscribeToTranscriptItem(handleTranscriptItem: @escaping (TranscriptItem) -> Void) -> AnyCancellable {
        let subscription = transcriptItemPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { transcriptItem in
                handleTranscriptItem(transcriptItem)
            })
        transcriptItemCancellables.insert(subscription)
        return subscription
    }
    
    // Update transcript dictionary and notify subscribers
    private func updateTranscriptDict(with item: TranscriptItem) {
        switch item {
        case let metadata as Metadata:
            // metadata.id here refers to messageId attatched to a metadata
            if let messageItem = transcriptDict[metadata.id] as? Message {
                messageItem.metadata = metadata
                transcriptDict[metadata.id] = messageItem
            }
        case let message as Message:
            // Remove typing indicators when a new message from the agent is received
            if message.participant == Constants.AGENT {
                removeTypingIndicators()
            }
            if let tempMessageId = attachmentIdToTempMessageIdMap[message.attachmentId ?? ""] {
                if let tempMessage = transcriptDict[tempMessageId] as? Message {
                    updateTemporaryMessage(tempMessage: tempMessage, with: message, in: &transcriptDict)
                }
                attachmentIdToTempMessageIdMap.removeValue(forKey: message.attachmentId ?? "")
            } else {
                transcriptDict[message.id] = message
            }
        case let event as Event:
            handleEvent(event, in: &transcriptDict)
        default:
            break
        }
        
        if let updatedItem = transcriptDict[item.id] {
            self.handleTranscriptItemUpdate(updatedItem)
        }
    }
    
    private func updateTemporaryMessage(tempMessage: Message, with message: Message, in currentDict: inout [String: TranscriptItem]) {
        tempMessage.updateId(message.id)
        tempMessage.updateTimeStamp(message.timeStamp)
        tempMessage.text = message.text
        tempMessage.contentType = message.contentType
        tempMessage.attachmentId = message.attachmentId
        
        currentDict.removeValue(forKey: tempMessage.id)
        currentDict[message.id] = tempMessage
        self.handleTranscriptItemUpdate(tempMessage)
    }
    
    private func handleEvent(_ event: Event, in currentDict: inout [String: TranscriptItem]) {
        if event.contentType == ContentType.typing.rawValue {
            currentDict[event.id] = event
            resetTypingIndicatorTimer(after: 12.0)
        } else {
            currentDict[event.id] = event
        }
    }
    
    private func resetTypingIndicatorTimer(after: Double = 0.0) {
        typingIndicatorTimer?.invalidate()
        typingIndicatorTimer = Timer.scheduledTimer(withTimeInterval: after, repeats: false) { [weak self] _ in
            self?.removeTypingIndicators()
        }
    }
    
    private func removeTypingIndicators() {
        typingIndicatorTimer?.invalidate()
        let initialCount = transcriptDict.count
        
        for (key, item) in transcriptDict where item is Event && (item as? Event)?.contentType == ContentType.typing.rawValue {
            transcriptDict.removeValue(forKey: key)
            internalTranscript.removeAll { $0.id == key }
        }
        
        if transcriptDict.count != initialCount {
            transcriptListPublisher.send(internalTranscript)
        }
    }
    
    
    private func sendSingleUpdateToClient(for message : Message){
        transcriptDict[message.id] = message
        self.handleTranscriptItemUpdate(message)
    }

    
    private func handleTranscriptItemUpdate(_ transcriptItem: TranscriptItem) {
        // Send out individual transcript item
        self.transcriptItemPublisher.send(transcriptItem)
        
        if let index = internalTranscript.firstIndex(where: { $0.id == transcriptItem.id }) {
            // Update existing item
            internalTranscript[index] = transcriptItem
        } else {
            // Insert new item based on timestamp comparison
            if let firstItem = internalTranscript.first, transcriptItem.timeStamp < firstItem.timeStamp {
                internalTranscript.insert(transcriptItem, at: 0)
            } else {
                internalTranscript.append(transcriptItem)
            }
        }
        
        // Send out updated transcript
        self.transcriptListPublisher.send(internalTranscript)
    }
    
    func subscribeToTranscriptList(handleTranscriptList: @escaping ([TranscriptItem]) -> Void) -> AnyCancellable {
        let subscription = transcriptListPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { updatedTranscript in
                handleTranscriptList(updatedTranscript)
            })
        transcriptListCancellables.insert(subscription)
        return subscription
    }
    
    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void) {
        if (!connectionDetailsProvider.isChatSessionActive()) {
            self.websocketManager?.disconnect(reason: "Session inactive")
            self.clearSubscriptionsAndPublishers()
            completion(true, nil)
            return
        }
        
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
            completion(false, error)
            return
        }
        
        messageReceiptsManager?.invalidateTimer()
        
        awsClient.disconnectParticipantConnection(connectionToken: connectionDetails.connectionToken!) { result in
            switch result {
            case .success(_):
                SDKLogger.logger.logDebug("Participant Disconnected")
                self.eventPublisher.send(.chatEnded)
                self.websocketManager?.disconnect(reason: "Participant Disconnected")
                self.clearSubscriptionsAndPublishers()
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func suspendWebSocketConnection() {
        SDKLogger.logger.logDebug("Suspending WebSocket connections")
        self.websocketManager?.suspendWebSocketConnection()
    }
    
    func resumeWebSocketConnection() {
        SDKLogger.logger.logDebug("Resuming WebSocket connections")
        self.websocketManager?.resumeWebSocketConnection()
    }
    
    func reset() {
        self.websocketManager?.disconnect(reason: "Participant Disconnected")
        self.clearSubscriptionsAndPublishers()
        self.messageReceiptsManager?.reset()
        connectionDetailsProvider.reset()
        self.attachmentIdToTempMessageIdMap = [:]
        self.transcriptDict = [:]
        self.tempMessageIdToFileUrl = [:]
    }
    
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
            completion(false, error)
            return
        }
        
        let recentlySentMessage = TranscriptItemUtils.createDummyMessage(content: message, contentType: contentType.rawValue, status: .Sending, displayName: getRecentDisplayName())
        
        self.sendSingleUpdateToClient(for: recentlySentMessage)
        
        self.awsClient.sendMessage(connectionToken: connectionDetails.connectionToken!, contentType: contentType, message: message) { result in
            switch result {
            case .success(let response):
                MetricsClient.shared.triggerCountMetric(metricName: .SendMessage)
                if let id = response.identifier {
                    self.updatePlaceholderMessage(oldId: recentlySentMessage.id, newId: id)
                }
                completion(true, nil)
            case .failure(let error):
                recentlySentMessage.metadata?.status = .Failed
                self.sendSingleUpdateToClient(for: recentlySentMessage)
                completion(false, error)
            }
        }
    }
    
    private func getRecentDisplayName() -> String {
        let recentCustomerMessage = transcriptDict.values
            .compactMap { $0 as? Message }
            .filter { $0.participant == "CUSTOMER" }
            .sorted { $0.timeStamp > $1.timeStamp }
            .first
        return recentCustomerMessage?.displayName ?? ""
    }
    
    private func updatePlaceholderMessage(oldId: String, newId: String) {
        if let placeholderMessage = transcriptDict[oldId] as? Message {
            if transcriptDict[newId] != nil {
                transcriptDict.removeValue(forKey: oldId)
                internalTranscript.removeAll { $0.id == oldId }
                // Send out updated transcript
                self.transcriptListPublisher.send(internalTranscript)
            } else {
                // Update the placeholder message's ID to the new ID
                placeholderMessage.updateId(newId)
                placeholderMessage.metadata?.status = .Sent
                transcriptDict.removeValue(forKey: oldId)
                transcriptDict[newId] = placeholderMessage
            }
            transcriptItemPublisher.send(placeholderMessage)
        }
    }
    
    func resendFailedMessage(messageId: String, completion: @escaping (Bool, Error?) -> Void) {
        let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find the failed message"])
        
        // cannot retry if old message didn't exist or fail to be sent
        guard let oldMessage = transcriptDict[messageId] as? Message,
           let status = oldMessage.metadata?.status,
           [.Failed, .Unknown].contains(status) else {
            completion(false, error)
            return
        }

        // remove failed message from transcript & transcript dict
        internalTranscript.removeAll { $0.id == messageId }
        transcriptDict.removeValue(forKey: messageId)
        // Send out updated transcript with old message removed
        self.transcriptListPublisher.send(internalTranscript)

        // as the next step, attempt to resend the message based on its type
        // if old message is an attachment
        if let attachmentUrl = tempMessageIdToFileUrl[messageId] {
            self.sendAttachment(file: attachmentUrl, completion: completion)
        } else {
            if let contentType = ContentType(rawValue: oldMessage.contentType) {
                self.sendMessage(contentType: contentType, message: oldMessage.text, completion: completion)
            } else {
                completion(false, error)
            }
        }
    }
    
    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
            completion(false, error)
            return
        }
        
        if event == .typing {
            if !throttleTypingEvent {
                throttleTypingEvent = true
                self.throttleTypingEventTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                    if self.throttleTypingEvent {
                        self.throttleTypingEvent = false
                        self.throttleTypingEventTimer?.invalidate()
                    }
                }
            } else {
                completion(true, nil)
                return
            }
        }
        
        awsClient.sendEvent(connectionToken: connectionDetails.connectionToken!,contentType: event, content: content!) { result in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func sendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let messageReceiptsManager = messageReceiptsManager else {
            SDKLogger.logger.logError("messageReceiptsManager is not defined")
            return
        }

        messageReceiptsManager.throttleAndSendMessageReceipt(event: event, messageId: messageId) { result in
            switch result {
            case .success(let pendingMessageReceipts):
                self.sendPendingMessageReceipts(pendingMessageReceipts: pendingMessageReceipts) { result in
                    switch result {
                    case .success(let messageReceiptType):
                        switch messageReceiptType {
                        case .messageDelivered:
                            SDKLogger.logger.logDebug("Delivered receipt sent for message id: \(String(describing: pendingMessageReceipts.deliveredReceiptMessageId))")
                            completion(.success(()))
                            break
                        case .messageRead:
                            SDKLogger.logger.logDebug("Read receipt sent for message id: \(String(describing: pendingMessageReceipts.deliveredReceiptMessageId))")
                            completion(.success(()))
                            break
                        }
                    case .failure(let error):
                        SDKLogger.logger.logError("Pending message receipts could not be sent: \(String(describing: error))")
                        completion(.failure(error))
                        break
                    }
                }
            case .failure(let error):
                SDKLogger.logger.logError("Error sending message receipt: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func sendPendingMessageReceipts(pendingMessageReceipts: PendingMessageReceipts, completion: @escaping (Result<MessageReceiptType, Error>) -> Void) {
        if pendingMessageReceipts.readReceiptMessageId != nil {
            let content = "{\"messageId\":\"\(pendingMessageReceipts.readReceiptMessageId!)\"}"
            sendEvent(event: MessageReceiptType.messageRead.toContentType(), content: content) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        SDKLogger.logger.logError("Error sending read receipt for message \(pendingMessageReceipts.readReceiptMessageId ?? "unknown"): \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        completion(.success(.messageRead))
                    }
                }
            }
        }
        
        if pendingMessageReceipts.deliveredReceiptMessageId != nil {
            let content = "{\"messageId\":\"\(pendingMessageReceipts.deliveredReceiptMessageId!)\"}"
            sendEvent(event: MessageReceiptType.messageDelivered.toContentType(), content: content) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        SDKLogger.logger.logError("Error sending delivered receipt for message \(pendingMessageReceipts.deliveredReceiptMessageId!): \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        completion(.success(.messageDelivered))
                    }
                }
            }
        }
    }
    
    func sendAttachment(file: URL, completion: @escaping(Bool, Error?) -> Void) {
        var mimeType: String?
        var fileSize: Int?
        
        if let typeIdentifier = UTType(filenameExtension: file.pathExtension),
           let mime = typeIdentifier.preferredMIMEType {
            if AttachmentTypes(rawValue: mime) != nil {
                mimeType = mime
            } else {
                let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(mime) is not a supported file type"])
                completion(false, error)
                return
            }
        } else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse MIME type from file URL"])
            completion(false, error)
            return
        }
        
        let fileName = file.lastPathComponent
        
        if let fileSizeValue = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            fileSize = fileSizeValue
        } else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get valid file size"])
            completion(false, error)
            return
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFilePathUrl = tempDirectory.appendingPathComponent(fileName)
        if file != tempFilePathUrl {
            if (FileManager.default.fileExists(atPath: tempFilePathUrl.path)) {
                do {
                    // Delete the existing file
                    try FileManager.default.removeItem(at: tempFilePathUrl)
                    print("Existing file deleted successfully.")
                } catch {
                    print("Error deleting existing file: \(error)")
                    completion(false, error)
                    return
                }
            }
            do {
                try FileManager.default.copyItem(at: file, to: tempFilePathUrl)
            } catch let error {
                completion(false, error)
            }
        }
        
        let recentlySentAttachmentMessage = TranscriptItemUtils.createDummyMessage(content: file.lastPathComponent, contentType:mimeType!, status: .Sending, attachmentId: UUID().uuidString, displayName: getRecentDisplayName())
        
        tempMessageIdToFileUrl[recentlySentAttachmentMessage.id] = tempFilePathUrl
        self.sendSingleUpdateToClient(for: recentlySentAttachmentMessage)
        
        self.startAttachmentUpload(contentType: mimeType!, attachmentName: fileName, attachmentSizeInBytes: fileSize!) { result in
            switch result {
            case .success(let response):
                // Update the dictionary with actual attachmentId
                self.attachmentIdToTempMessageIdMap[response.attachmentId!] = recentlySentAttachmentMessage.id
                self.apiClient.uploadAttachment(file: file, response: response) { success, error in
                    if success {
                        self.completeAttachmentUpload(attachmentIds: [response.attachmentId!]) { success, error in
                            if success {
                                do {
                                    // Delete the existing file
                                    try FileManager.default.removeItem(at: tempFilePathUrl)
                                } catch {
                                    print("Error deleting existing file after successful upload: \(error)")
                                }
                                completion(true, nil)
                            } else {
                                self.handleAttachmentUploadFailure(message: recentlySentAttachmentMessage, error: error)
                                completion(false, error)
                            }
                        }
                    } else if error != nil {
                        print("Attachment upload failed: \(String(describing: error))")
                    } else {
                        print("Attachment upload failed")
                    }
                }
            case .failure(let error):
                self.handleAttachmentUploadFailure(message: recentlySentAttachmentMessage, error: error)
                completion(false, error)
            }
        }
    }
    
    
    private func handleAttachmentUploadFailure(message: Message, error: Error?) {
        message.metadata?.status = .Failed
        self.sendSingleUpdateToClient(for: message)
    }
    
    func startAttachmentUpload(contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            completion(.failure(NSError()))
            return
        }
        
        awsClient.startAttachmentUpload(connectionToken: connectionDetails.connectionToken!, contentType: contentType, attachmentName: attachmentName, attachmentSizeInBytes: attachmentSizeInBytes) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func completeAttachmentUpload(attachmentIds: [String], completion: @escaping (Bool, Error?) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            completion(false, NSError())
            return
        }
        
        awsClient.completeAttachmentUpload(connectionToken: connectionDetails.connectionToken!, attachmentIds: attachmentIds) { result in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                print("Complete attachmentUpload failed: \(String(describing: error))")
                completion(false, error)
            }
        }
    }
    
    func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            completion(.failure(NSError()))
            return
        }
        
        awsClient.getAttachment(connectionToken: connectionDetails.connectionToken!, attachmentId: attachmentId) { result in
            switch result {
            case .success(let response):
                if let url = URL(string: response.url!) {
                    completion(.success(url))
                } else {
                    completion(.failure(NSError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        getAttachmentDownloadUrl(attachmentId: attachmentId) { result in
            switch result {
            case .success(let url):
                self.downloadFile(url: url, filename: filename) { (localUrl, error) in
                    if let localUrl = localUrl {
                        print("File successfully downloaded to temporary directory")
                        completion(.success(localUrl))
                    } else if let error = error {
                        print("Failed to download file: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
            }
        }
    
    func downloadFile(url: URL, filename: String, completion: @escaping (URL?, Error?) -> Void) {
        let downloadTask = urlSession.downloadTask(with: url) { (tempLocalUrl, response, error) in
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let tempLocalUrl = tempLocalUrl else {
                print("No file found at URL")
                completion(nil, NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No file found at URL"]))
                return
            }
            
            do {
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFilePathUrl = tempDirectory.appendingPathComponent(filename)

                
                if FileManager.default.fileExists(atPath: tempFilePathUrl.path) {
                    do {
                        // Delete the existing file
                        try FileManager.default.removeItem(at: tempFilePathUrl)
                        print("Existing file deleted successfully.")
                    } catch {
                        print("Error deleting existing file: \(error)")
                        completion(nil, error)
                        return
                    }
                }
                
                try FileManager.default.moveItem(at: tempLocalUrl, to: tempFilePathUrl)
                completion(tempFilePathUrl, nil)
            } catch let error {
                completion(nil, error)
            }
        }
        
        downloadTask.resume()
    }
    
    
    func fetchReconnectedTranscript() {
        guard let lastItem = internalTranscript.last(where: { ($0 as? Message)?.metadata?.status != .Failed }) else {
            return
        }

        // Construct the start position from the last item
        let startPosition = AWSConnectParticipantStartPosition()
        startPosition?.identifier = lastItem.id

        // Fetch the transcript starting from the last item
        fetchTranscriptWith(startPosition: startPosition)
    }
    
    private func isItemInInternalTranscript(Id: String) -> Bool {
        for item in internalTranscript.reversed() {
            if item.id == Id {
                return true
            }
        }
        return false
    }

    private func fetchTranscriptWith(startPosition: AWSConnectParticipantStartPosition?) {
        self.getTranscript(scanDirection: .forward, startPosition: startPosition) { [weak self] result in
            switch result {
            case .success(let transcriptResponse):
                // Process the received transcript items
                if let self = self {
                    if let lastItem = transcriptResponse.transcript.last, !(transcriptResponse.nextToken.isEmpty || isItemInInternalTranscript(Id: lastItem.id)) {
                        // Continue fetching if there are more messages to fetch.
                        var newStartPosition = AWSConnectParticipantStartPosition()                      
                        newStartPosition?.identifier = lastItem.id
                        self.fetchTranscriptWith(startPosition: newStartPosition)
                    }
                }
            case .failure(let error):
                // Handle error (e.g., log or show an error message)
                print("Error fetching transcript: \(error.localizedDescription)")
            }
        }
    }

    
    func getTranscript(
        scanDirection: AWSConnectParticipantScanDirection? = nil,
        sortOrder: AWSConnectParticipantSortKey? = nil,
        maxResults: NSNumber? = nil,
        nextToken: String? = nil,
        startPosition: AWSConnectParticipantStartPosition? = nil,
        completion: @escaping (Result<TranscriptResponse, Error>) -> Void
    ) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
            completion(.failure(error))
            return
        }
        
        let getTranscriptArgs = AWSConnectParticipantGetTranscriptRequest()
        getTranscriptArgs?.connectionToken = connectionDetails.connectionToken
        getTranscriptArgs?.scanDirection = scanDirection ?? .backward
        getTranscriptArgs?.sortOrder = sortOrder ?? .ascending
        getTranscriptArgs?.maxResults = maxResults ?? 30
        getTranscriptArgs?.startPosition = startPosition
        if ((nextToken?.isEmpty) == false){
            getTranscriptArgs?.nextToken = nextToken
        }
        
        awsClient.getTranscript(getTranscriptArgs: getTranscriptArgs!) { [weak self] result in
            switch result {
            case .success(let response):
                
                guard let transcriptItems = response.transcript else {
                    completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transcript items are nil"])))
                    return
                }
                
                if let websocketManager = self?.websocketManager {
                    let formattedItems = websocketManager.formatAndProcessTranscriptItems(transcriptItems)
                    let transcriptResponse = TranscriptResponse(
                        initialContactId: response.initialContactId ?? "",
                        nextToken: response.nextToken ?? "", // Handle nextToken if it is available in the response
                        transcript: formattedItems
                    )
                    completion(.success(transcriptResponse))
                } else {
                    completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebsocketManager is not available"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func configure(config: GlobalConfig) {
        let messageReceiptConfig = config.features.messageReceipts
        messageReceiptsManager?.throttleTime = messageReceiptConfig.throttleTime
        messageReceiptsManager?.shouldSendMessageReceipts = messageReceiptConfig.shouldSendMessageReceipts
        MetricsClient.shared.configureMetricsManager(config: config)
    }
    
    func getConnectionDetailsProvider() -> any ConnectionDetailsProviderProtocol {
        return connectionDetailsProvider
    }
    
    func registerNotificationListeners() {
        NotificationCenter.default.addObserver(forName: .requestNewWsUrl, object: nil, queue: .main) { [weak self] _ in
            if let pToken = self?.connectionDetailsProvider.getChatDetails()?.participantToken {
                self?.awsClient.createParticipantConnection(participantToken: pToken) { result in
                    switch result {
                    case .success(let connectionDetails):
                        self?.connectionDetailsProvider.updateConnectionDetails(newDetails: connectionDetails)
                        if let wsUrl = URL(string: connectionDetails.websocketUrl ?? "") {
                            self?.websocketManager?.connect(wsUrl: wsUrl, isReconnect: true)
                        }
                    case .failure(let error):
                        if error.localizedDescription == "Access denied" {
                            self?.updateTranscriptDict(with: TranscriptItemUtils.createDummyEndedEvent())
                            self?.eventPublisher.send(.chatEnded)
                        }
                        print("CreateParticipantConnection failed \(error)")
                    }
                }
            }
        }
    }
    
    private func clearSubscriptionsAndPublishers() {
        eventCancellables.forEach { $0.cancel() }
        transcriptItemCancellables.forEach { $0.cancel() }
        transcriptListCancellables.forEach { $0.cancel() }
        
        eventCancellables.removeAll()
        transcriptItemCancellables.removeAll()
        transcriptListCancellables.removeAll()
        
        eventPublisher = PassthroughSubject<ChatEvent, Never>()
        transcriptItemPublisher = PassthroughSubject<TranscriptItem, Never>()
        transcriptListPublisher = CurrentValueSubject<[TranscriptItem], Never>([])
        transcriptItemSet = Set<String>()
        transcriptDict = [:]
        internalTranscript = []
    }
    
}
