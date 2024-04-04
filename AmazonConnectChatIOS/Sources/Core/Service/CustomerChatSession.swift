//
//  CustomerChatSession.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation

class CustomerChatSession {
    private var chatDetails: ChatDetails
    private var options: ChatSessionOptions
    private var type: String
    
    // Controller or any other components for managing chat functionalities
    
    init(chatDetails: ChatDetails, options: ChatSessionOptions, type: String) {
        self.chatDetails = chatDetails
        self.options = options
        self.type = type
        // Initialize controller or other components
    }
    
    func connect(completion: @escaping (Bool, Error?) -> Void) {
            AWSClient.shared.createParticipantConnection(participantToken: self.chatDetails.participantToken) { success, websocketUrl, connectionToken, error in
                if success {
                    // Connection was successful, you can now proceed with chat functionalities
                    print("Connection successful with WebSocket URL: \(websocketUrl ?? "Unavailable")")
                    completion(true, nil)
                } else {
                    print("Connection failed with error: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false, error)
                }
            }
        }
    
    func onMessage(callback: @escaping (String) -> Void) {
        // Subscribe to incoming message events
    }

    // Implement other methods (onDeliveredReceipt, onConnectionBroken, etc.) similarly...
}
