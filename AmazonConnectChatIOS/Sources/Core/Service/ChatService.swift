// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import Combine
import AWSConnectParticipant

protocol ChatServiceProtocol {
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void)
    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void)
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void)
    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void)
    func subscribeToEvents(handleEvent: @escaping (ChatEvent) -> Void) -> AnyCancellable
    func subscribeToTranscriptItem(handleTranscriptItem: @escaping (TranscriptItem) -> Void) -> AnyCancellable
    func subscribeToTranscriptList(handleTranscriptList: @escaping ([TranscriptItem]) -> Void) -> AnyCancellable
    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<TranscriptResponse, Error>) -> Void)
}

class ChatService : ChatServiceProtocol {
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptItemPublisher = PassthroughSubject<TranscriptItem, Never>()
    var transcriptListPublisher = CurrentValueSubject<[TranscriptItem], Never>([])
    private var eventCancellables = Set<AnyCancellable>()
    private var transcriptItemCancellables = Set<AnyCancellable>()
    private var transcriptListCancellables = Set<AnyCancellable>()
    private let connectionDetailsProvider: ConnectionDetailsProviderProtocol
    private var awsClient: AWSClientProtocol
    private var websocketManager: WebsocketManagerProtocol?
    private var websocketManagerFactory: (URL) -> WebsocketManagerProtocol
    
    init(awsClient: AWSClientProtocol = AWSClient.shared,
         connectionDetailsProvider: ConnectionDetailsProviderProtocol = ConnectionDetailsProvider.shared,
         websocketManagerFactory: @escaping (URL) -> WebsocketManagerProtocol = { WebsocketManager(wsUrl: $0) }) {
        self.awsClient = awsClient
        self.connectionDetailsProvider = connectionDetailsProvider
        self.websocketManagerFactory = websocketManagerFactory
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
            })
            .store(in: &eventCancellables)
        
        self.websocketManager?.transcriptPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] transcriptItem in
                self?.transcriptItemPublisher.send(transcriptItem)
                self?.updateTranscriptList(with: transcriptItem)
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
        currentList.append(item)
        // Avoid sending empty transcript update
        if !currentList.isEmpty {
            transcriptListPublisher.send(currentList)  // Send updated list to all subscribers
        }
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
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
            completion(false, error)
            return
        }
        
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
    
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            let error = NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection details available"])
            completion(false, error)
            return
        }
        
        awsClient.sendMessage(connectionToken: connectionDetails.connectionToken!, contentType: contentType, message: message) { result in
            switch result {
            case .success(_):
                MetricsClient.shared.triggerCountMetric(metricName: .SendMessage)
                completion(true, nil)
            case .failure(let error):
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
        
        awsClient.sendEvent(connectionToken: connectionDetails.connectionToken!,contentType: event, content: content!) { result in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
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
        getTranscriptArgs?.maxResults = maxResults ?? 15
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
    
    
    func registerNotificationListeners() {
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
    }
    
}
