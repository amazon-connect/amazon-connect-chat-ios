// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import Combine
import AWSConnectParticipant
import UniformTypeIdentifiers
import UIKit

protocol ChatServiceProtocol {
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void)
    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void)
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void)
    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void)
    func sendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func sendPendingMessageReceipts(pendingMessageReceipts: PendingMessageReceipts, completion: @escaping (Result<MessageReceiptType, Error>) -> Void)
    func sendAttachment(file: URL, completion: @escaping (Bool, Error?) -> Void)
    func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void)
    func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL, Error>) -> Void)
    func subscribeToEvents(handleEvent: @escaping (ChatEvent) -> Void) -> AnyCancellable
    func subscribeToTranscriptItem(handleTranscriptItem: @escaping (TranscriptItem) -> Void) -> AnyCancellable
    func subscribeToTranscriptList(handleTranscriptList: @escaping ([TranscriptItem]) -> Void) -> AnyCancellable
    func subscribeToTranscriptDict(handleTranscriptDict: @escaping ([String: TranscriptItem]) -> Void) -> AnyCancellable
    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<TranscriptResponse, Error>) -> Void)
}

class ChatService : ChatServiceProtocol {
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptItemPublisher = PassthroughSubject<TranscriptItem, Never>()
    var transcriptListPublisher = CurrentValueSubject<[TranscriptItem], Never>([])
    var urlSession = URLSession(configuration: .default)
    var apiClient: APIClientProtocol = APIClient.shared
    var messageReceiptsManager: MessageReceiptsManagerProtocol?
    private var eventCancellables = Set<AnyCancellable>()
    private var transcriptItemCancellables = Set<AnyCancellable>()
    private var transcriptListCancellables = Set<AnyCancellable>()
    private let connectionDetailsProvider: ConnectionDetailsProviderProtocol
    private var awsClient: AWSClientProtocol
    private var websocketManager: WebsocketManagerProtocol?
    private var websocketManagerFactory: (URL) -> WebsocketManagerProtocol
    private var throttleTypingEvent: Bool = false
    private var throttleTypingEventTimer: Timer?
    private var transcriptItemSet = Set<String>()
    private var messageDict: [String: Message] = [:]
    var transcriptDictPublisher = CurrentValueSubject<[String: TranscriptItem], Never>([:])
    private var transcriptDictCancellables = Set<AnyCancellable>()


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
                self?.eventPublisher.send(event)
                if (event == .chatEnded) {
                    self?.messageReceiptsManager?.invalidateTimer()
                }
            })
            .store(in: &eventCancellables)
        
        self.websocketManager?.transcriptPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] transcriptItem in
                self?.transcriptItemPublisher.send(transcriptItem)
//                self?.updateTranscriptList(with: transcriptItem)
                self?.updateTranscriptDict(with: transcriptItem)
            })
            .store(in: &transcriptItemCancellables)
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
    
    // Update transcript list and notify subscribers
    private func updateTranscriptList(with item: TranscriptItem) {
        var currentList = transcriptListPublisher.value
        //Remove previous typing indicators
        currentList.removeAll { $0 is Event && ($0 as? Event)?.contentType == ContentType.typing.rawValue }
        
        if let metadata = item as? Metadata {
            if let messageItem = self.messageDict[metadata.id]{
                messageItem.metadata = metadata
                // Update the message in the current list
                if let messageIndex = currentList.firstIndex(where: { $0.id == metadata.id }) {
                    currentList[messageIndex] = messageItem
                }
            }
        }
        else if let message = item as? Message {
            if let tempMessageIndex = currentList.firstIndex(where: { $0.id == message.id }) {
                // Update the temporary message with actual data
                currentList[tempMessageIndex] = message
                self.messageDict[message.id] = message
            } else if !transcriptItemSet.contains(message.id) {
                // Add the new message
                transcriptItemSet.insert(message.id)
                self.messageDict[message.id] = message
                currentList.append(message)
            }
        }
        else if let event = item as? Event  {
            // Event
            if (transcriptItemSet.contains(event.id)) {
                return
            }
            transcriptItemSet.insert(event.id)
            currentList.append(event)
        }
        
        // Avoid sending empty transcript update
        transcriptListPublisher.send(currentList)  // Send updated list to all subscribers
        
    }
    
    // Update transcript dictionary and notify subscribers
        private func updateTranscriptDict(with item: TranscriptItem) {
            var currentDict = transcriptDictPublisher.value

            if let metadata = item as? Metadata {
                if let messageItem = self.messageDict[metadata.id] {
                    messageItem.metadata = metadata
                    currentDict[metadata.id] = messageItem
                }
            } else if let message = item as? Message {
                currentDict[message.id] = message
                self.messageDict[message.id] = message
            } else if let event = item as? Event {
                currentDict[event.id] = event
            }

            transcriptDictPublisher.send(currentDict)  // Send updated dictionary to all subscribers
        }
    
    
    func subscribeToTranscriptDict(handleTranscriptDict: @escaping ([String: TranscriptItem]) -> Void) -> AnyCancellable {
            let subscription = transcriptDictPublisher
                .receive(on: RunLoop.main)
                .sink(receiveValue: { updatedTranscript in
                    handleTranscriptDict(updatedTranscript)
                })
            transcriptDictCancellables.insert(subscription)
            return subscription
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
    
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
            completion(false, error)
            return
        }
        
        // Create a temporary message ID and timestamp
        let temporaryMessageId = UUID().uuidString
        
        // Add the recently sent message to transcript temporarily
        let recentlySentMessage = Message(
            participant: "CUSTOMER",
            text: message,
            contentType: contentType.rawValue,
            messageDirection: MessageDirection.Outgoing,
            timeStamp: "Sending...",
            attachmentId: nil,
            messageId: temporaryMessageId,
            serializedContent: [:]
        )
        
//        var currentList = transcriptListPublisher.value
//        currentList.append(recentlySentMessage)
//        transcriptListPublisher.send(currentList)
        
        
        var currentDict = transcriptDictPublisher.value
        currentDict[temporaryMessageId] = recentlySentMessage
        transcriptDictPublisher.send(currentDict)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            
            self.awsClient.sendMessage(connectionToken: connectionDetails.connectionToken!, contentType: contentType, message: message) { result in
                switch result {
                case .success(let response):
                    MetricsClient.shared.triggerCountMetric(metricName: .SendMessage)
                    if let id = response.identifier {
                        self.updateMessageId(oldId: temporaryMessageId, newId: id)
                    }
                    completion(true, nil)
                case .failure(let error):
                    completion(false, error)
                    // Message failed to send
                }
            }
            
        }
    }
    
    private func updateMessageId(oldId: String, newId: String) {
//        var currentList = transcriptListPublisher.value
//        
//        if let index = currentList.firstIndex(where: { $0.id == oldId }) {
//            if let message = currentList[index] as? Message {
//                message.id = newId
//                currentList[index] = message
//                transcriptListPublisher.send(currentList)
//            }
//        }
        
        var currentDict = transcriptDictPublisher.value

                if let message = currentDict[oldId] as? Message {
                    message.id = newId
                    currentDict.removeValue(forKey: oldId)
                    currentDict[newId] = message
                    transcriptDictPublisher.send(currentDict)
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
        
        self.startAttachmentUpload(contentType: mimeType!, attachmentName: fileName, attachmentSizeInBytes: fileSize!) { result in
            switch result {
            case .success(let response):
                self.apiClient.uploadAttachment(file: file, response: response) { success, error in
                    if success {
                        self.completeAttachmentUpload(attachmentIds: [response.attachmentId!]) { success, error in
                            if success {
                                completion(true, nil)
                            } else {
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
                completion(false, error)
            }
        }
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
        
        awsClient.getTranscript(getTranscriptArgs: getTranscriptArgs!) { [weak self] result in
            switch result {
            case .success(let response):
                
                guard let transcriptItems = response.transcript else {
                    completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transcript items are nil"])))
                    return
                }
                
                if let websocketManager = self?.websocketManager {
                    let formattedItems = websocketManager.formatAndProcessTranscriptItems(transcriptItems)
                    print("DEBUG - OUT OF LOOP! \(String(describing: formattedItems))")
                    let transcriptResponse = TranscriptResponse(
                        initialContactId: response.initialContactId ?? "", // Assuming contactId is part of connectionDetails
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
    
    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void) {
        if (!ConnectionDetailsProvider.shared.isChatSessionActive()) {
            self.websocketManager?.disconnect()
            self.clearSubscriptionsAndPublishers()
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
                self.websocketManager?.disconnect()
                self.clearSubscriptionsAndPublishers()
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    
    func registerNotificationListeners() {
//        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
//            if (ConnectionDetailsProvider.shared.isChatSessionActive()) {
//                self?.getTranscript() {_ in }
//            }
//        }
        NotificationCenter.default.addObserver(forName: .requestNewWsUrl, object: nil, queue: .main) { [weak self] _ in
            if let pToken = self?.connectionDetailsProvider.getChatDetails()?.participantToken {
                self?.awsClient.createParticipantConnection(participantToken: pToken) { result in
                    switch result {
                    case .success(let connectionDetails):
                        self?.connectionDetailsProvider.updateConnectionDetails(newDetails: connectionDetails)
                        if let wsUrl = URL(string: connectionDetails.websocketUrl ?? "") {
                            self?.websocketManager?.connect(wsUrl: wsUrl)
                        }
                    case .failure(let error):
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
        transcriptDictPublisher = CurrentValueSubject<[String: TranscriptItem], Never>([:])
        transcriptItemSet = Set<String>()
        messageDict = [:]
    }
    
}
