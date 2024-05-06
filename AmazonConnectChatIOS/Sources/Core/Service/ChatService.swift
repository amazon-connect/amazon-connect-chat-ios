//
//  ChatService.swift
//  AmazonConnectChatIOS

import Foundation
import Combine

protocol ChatServiceProtocol {
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void)
    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void)
    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void)
    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void)
    func subscribeToEvents(handleEvent: @escaping (ChatEvent) -> Void) -> AnyCancellable
    func subscribeToMessages(handleMessage: @escaping (Message) -> Void) -> AnyCancellable
}

class ChatService : ChatServiceProtocol {
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var messagePublisher = PassthroughSubject<Message, Never>()
    private var eventCancellables = Set<AnyCancellable>()
    private var messageCancellables = Set<AnyCancellable>()
    private let connectionDetailsProvider = ConnectionDetailsProvider.shared
    private var awsClient: AWSClientProtocol
    private var websocketManager: WebsocketManager?

    
    init(awsClient: AWSClientProtocol = AWSClient.shared) {
        self.awsClient = awsClient
        self.registerNotificationListeners()
    }
    
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
        self.connectionDetailsProvider.updateChatDetails(newDetails: chatDetails)
        awsClient.createParticipantConnection(participantToken: chatDetails.participantToken) { result in
            switch result {
            case .success(let connectionDetails):
                print("Participant connection created: WebSocket URL - \(connectionDetails.websocketUrl ?? "N/A")")
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
    
    private func setupWebSocket(url: URL) {
        self.websocketManager = WebsocketManager(wsUrl: url)
        
        self.websocketManager?.eventPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] event in
                print("Received event from WebsocketManager: \(event)")
                self?.eventPublisher.send(event)
            })
            .store(in: &eventCancellables)
        
        self.websocketManager?.messagePublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] message in
                print("Received event from WebsocketManager: \(message)")
                self?.messagePublisher.send(message)
            })
            .store(in: &messageCancellables)
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
    
    func subscribeToMessages(handleMessage: @escaping (Message) -> Void) -> AnyCancellable {
        let subscription = messagePublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { message in
                print("Message received in ChatService: \(message)")
                handleMessage(message)
            })
        messageCancellables.insert(subscription)
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
                    }
                }
            }
            .store(in: &eventCancellables)
    }
    
}
