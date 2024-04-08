//
//  ChatService.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation

protocol ChatServiceProtocol {
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void)
}

class ChatService : ChatServiceProtocol {
    private var awsClient: AWSClientProtocol

    init(awsClient: AWSClientProtocol = AWSClient.shared) {
           self.awsClient = awsClient
       }
    
    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
        awsClient.createParticipantConnection(participantToken: chatDetails.participantToken) { success, websocketUrl, connectionToken, error in
            if success {
                // Assume further setup with websocketUrl and connectionToken for real chat session
                print("Participant connection created: WebSocket URL - \(websocketUrl ?? "N/A")")
                
            }
            completion(success, error)
        }
    }
    
    // Additional functionalities as needed, e.g., sendMessage, endChatSession, etc.
}
