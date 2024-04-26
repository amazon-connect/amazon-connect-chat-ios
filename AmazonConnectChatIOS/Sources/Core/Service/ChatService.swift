//
//  ChatService.swift
//  AmazonConnectChatIOS

import Foundation

protocol ChatServiceProtocol {
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void)
    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void)
    func sendMessage(message: String, completion: @escaping (Bool, Error?) -> Void)
    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void)
    func onMessageReceived(_ callback: @escaping (Message) -> Void)
    func onConnected(_ callback: @escaping () -> Void)
    func onDisconnected(_ callback: @escaping () -> Void)
    func onError(_ callback: @escaping (Error?) -> Void)
}

class ChatService : ChatServiceProtocol {
    
    private let connectionDetailsProvider = ConnectionDetailsProvider.shared
    private var awsClient: AWSClientProtocol
    private var websocketManager: WebsocketManager?
    private var chatDetails: ChatDetails?
    
    private var messageReceivedCallback: ((Message) -> Void)?
    private var onConnectedCallback: (() -> Void)?
    private var onDisconnectedCallback: (() -> Void)?
    private var onErrorCallback: ((Error?) -> Void)?
    
    init(awsClient: AWSClientProtocol = AWSClient.shared) {
        self.awsClient = awsClient
        self.registerNotificationListeners()
    }
    
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
        awsClient.createParticipantConnection(participantToken: chatDetails.participantToken) { result in
            switch result {
            case .success(let connectionDetails):
                print("Participant connection created: WebSocket URL - \(connectionDetails.websocketUrl ?? "N/A")")
                self.connectionDetailsProvider.updateConnectionDetails(newDetails: connectionDetails)
                if let wsUrl = URL(string: connectionDetails.websocketUrl ?? "") {
                    self.setupWebSocket(url: wsUrl)
                }
                self.chatDetails = chatDetails
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    private func setupWebSocket(url: URL) {
        websocketManager = WebsocketManager(wsUrl: url, onRecievedMessage: { [weak self] message in
            self?.messageReceivedCallback?(message)
        })
        
        websocketManager?.onConnected = {
            self.onConnectedCallback?()
        }
        websocketManager?.onDisconnected = {
            self.onDisconnectedCallback?()
        }
        websocketManager?.onError = { error in
            self.onErrorCallback?(error)
        }
    }
    
    func onMessageReceived(_ callback: @escaping (Message) -> Void) {
        messageReceivedCallback = callback
    }
    
    func onConnected(_ callback: @escaping () -> Void) {
        onConnectedCallback = callback
    }
    
    func onDisconnected(_ callback: @escaping () -> Void) {
        onDisconnectedCallback = callback
    }
    
    func onError(_ callback: @escaping (Error?) -> Void) {
        onErrorCallback = callback
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
                self.websocketManager?.disconnect()
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func sendMessage(message: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let connectionDetails = connectionDetailsProvider.getConnectionDetails() else {
            completion(false, NSError())
            return
        }
        
        awsClient.sendMessage(connectionToken: connectionDetails.connectionToken!, message: message) { result in
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
        NotificationCenter.default.addObserver(forName: .requestNewWsUrl, object: nil, queue: .main) { [weak self] _ in
            if let pToken = self?.chatDetails?.participantToken {
                self?.awsClient.createParticipantConnection(participantToken: pToken) { result in
                    switch result {
                    case .success(let connectionDetails):
                        print("Participant connection created: WebSocket URL - \(connectionDetails.websocketUrl ?? "N/A")")
                        self?.connectionDetailsProvider.updateConnectionDetails(newDetails: connectionDetails)
                        if let wsUrl = URL(string: connectionDetails.websocketUrl ?? "") {
                            self?.websocketManager?.connect(wsUrl: wsUrl)
                        }
                    case .failure(let error):
                        print("CreateParticipantConnection failed")
                    }
                }
            }
        }
    }
}
