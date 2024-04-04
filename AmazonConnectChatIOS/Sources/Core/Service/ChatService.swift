//
//  ChatService.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation

class ChatService {
    private var awsClient = AWSClient.shared
    
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
