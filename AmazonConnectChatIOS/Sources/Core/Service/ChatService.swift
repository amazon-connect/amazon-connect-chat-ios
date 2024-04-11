//
//  ChatService.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation

protocol ChatServiceProtocol {
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void)
    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void)
}

class ChatService : ChatServiceProtocol {
    private let connectionDetailsProvider = ConnectionDetailsProvider.shared
    private var awsClient: AWSClientProtocol
    
    init(awsClient: AWSClientProtocol = AWSClient.shared) {
        self.awsClient = awsClient
    }
    
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
        awsClient.createParticipantConnection(participantToken: chatDetails.participantToken) { result in
            switch result {
            case .success(let connectionDetails):
                print("Participant connection created: WebSocket URL - \(connectionDetails.websocketUrl ?? "N/A")")
                self.connectionDetailsProvider.updateConnectionDetails(newDetails: connectionDetails)
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
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
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    
    // Additional functionalities as needed, e.g., sendMessage, endChatSession, etc.
}
