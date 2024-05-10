//
//  ChatService.swift
//  AmazonConnectChatIOS

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
    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<[AWSConnectParticipantItem], Error>) -> Void)
}

class ChatService : ChatServiceProtocol {
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptItemPublisher = PassthroughSubject<TranscriptItem, Never>()
    var transcriptListPublisher = CurrentValueSubject<[TranscriptItem], Never>([])
    private var eventCancellables = Set<AnyCancellable>()
    private var transcriptItemCancellables = Set<AnyCancellable>()
    private var transcriptListCancellables = Set<AnyCancellable>()
    private let connectionDetailsProvider = ConnectionDetailsProvider.shared
    private var awsClient: AWSClientProtocol
    private var websocketManager: WebsocketManager?
    var customMessages: CustomMessages?
    
    init(awsClient: AWSClientProtocol = AWSClient.shared) {
        self.awsClient = awsClient
        self.registerNotificationListeners()
    }
    
    func setCustomMessages(_ messages: CustomMessages) {
        self.customMessages = messages
    }
    
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
        self.connectionDetailsProvider.updateChatDetails(newDetails: chatDetails)
        awsClient.createParticipantConnection(participantToken: chatDetails.participantToken) { result in
            switch result {
            case .success(let connectionDetails):
                SDKLogger.logger.logDebug("Participant connection created: WebSocket URL - \(connectionDetails.websocketUrl ?? "N/A")")
                self.connectionDetailsProvider.updateConnectionDetails(newDetails: connectionDetails)
                if let wsUrl = URL(string: connectionDetails.websocketUrl ?? "") {
                    self.setupWebSocket(url: wsUrl)
                }
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    private func overrideMessageText(for message: Message) -> String {
        switch message.contentType {
        case ContentType.joined.rawValue:
            return String(format: customMessages?.participantJoined ?? "%@ has joined the chat", message.participant)
        case ContentType.ended.rawValue:
            return customMessages?.chatEnded ?? "The chat has ended."
        case ContentType.left.rawValue:
            return String(format: customMessages?.participantLeft ?? "%@ has left the chat", message.participant)
        default:
            return message.text // Return original text if no customization is applicable
        }
    }
    
    private func setupWebSocket(url: URL) {
        self.websocketManager = WebsocketManager(wsUrl: url)
        
        self.websocketManager?.eventPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] event in
                print("Received event from WebsocketManager: \(event)")
                self?.eventPublisher.send(event)
            })
            .store(in: &eventCancellables)
        
        self.websocketManager?.transcriptPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] transcriptItem in
                print("Received item from WebsocketManager: \(transcriptItem)")
                self?.transcriptItemPublisher.send(transcriptItem)
                self?.updateTranscriptList(with: transcriptItem)
            })
            .store(in: &transcriptItemCancellables)
        
    }
    
    func subscribeToEvents(handleEvent: @escaping (ChatEvent) -> Void) -> AnyCancellable {
        let subscription = eventPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { event in
                print("Event received in ChatService: \(event)")
                handleEvent(event)
            })
        eventCancellables.insert(subscription)
        return subscription
    }
    
    func subscribeToTranscriptItem(handleTranscriptItem: @escaping (TranscriptItem) -> Void) -> AnyCancellable {
        let subscription = transcriptItemPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { transcriptItem in
                print("TranscriptItem received in ChatService: \(transcriptItem)")
                handleTranscriptItem(transcriptItem)
            })
        transcriptItemCancellables.insert(subscription)
        return subscription
    }
    
    // Update transcript list and notify subscribers
    private func updateTranscriptList(with item: TranscriptItem) {
        var currentList = transcriptListPublisher.value
        currentList.append(item)
        transcriptListPublisher.send(currentList)  // Send updated list to all subscribers
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
            completion(false, NSError())
            return
        }
        
        awsClient.disconnectParticipantConnection(connectionToken: connectionDetails.connectionToken!) { result in
            switch result {
            case .success(_):
                print("Participant Disconnected")
                self.eventPublisher.send(.chatEnded)
                self.websocketManager?.disconnect()
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            completion(false, NSError())
            return
        }
        
        awsClient.sendMessage(connectionToken: connectionDetails.connectionToken!, contentType: contentType, message: message) { result in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            completion(false, NSError())
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
    
    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<[AWSConnectParticipantItem], Error>) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            return
        }
        let getTranscriptArgs = AWSConnectParticipantGetTranscriptRequest()
        getTranscriptArgs?.connectionToken = connectionDetails.connectionToken
        getTranscriptArgs?.scanDirection = scanDirection ?? .backward
        getTranscriptArgs?.sortOrder = sortOrder ?? .ascending
        getTranscriptArgs?.maxResults = maxResults ?? 15
        getTranscriptArgs?.startPosition = startPosition
        
        awsClient.getTranscript(getTranscriptArgs: getTranscriptArgs!) { result in
            switch result {
            case .success(let items):
                completion(.success(items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func registerNotificationListeners() {
        NotificationCenter.default.publisher(for: .requestNewWsUrl, object: nil)
            .sink { [weak self] _ in
                if let pToken = self?.connectionDetailsProvider.getChatDetails()?.participantToken {
                    self?.awsClient.createParticipantConnection(participantToken: pToken) { result in
                        switch result {
                        case .success(let connectionDetails):
                            self?.connectionDetailsProvider.updateConnectionDetails(newDetails: connectionDetails)
                            if let wsUrl = URL(string: connectionDetails.websocketUrl ?? "") {
                                self?.websocketManager?.connect(wsUrl: wsUrl)
                            }
                        case .failure(let error):
                            print("CreateParticipantConnection failed: \(error)")
                        }
                    case .failure(let error):
                        print("CreateParticipantConnection failed \(error)")
                    }
                }
            }
            .store(in: &eventCancellables)
    }
    
}
