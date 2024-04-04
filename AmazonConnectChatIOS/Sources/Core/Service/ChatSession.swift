//
//  ChatSession.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation
import AWSCore

class ChatSession {
    static let shared = ChatSession()   // creates a single, static instance of ChatSession
    private var globalConfig: GlobalConfig?
    private var currentSession: CustomerChatSession?
    
    private init() {}  //prevents external instantiation
    
    func setGlobalConfig(_ config: GlobalConfig) {
        self.globalConfig = config
        AWSClient.shared.configure(with: config)
    }
    
    func createSession(chatDetails: ChatDetails, options: ChatSessionOptions? = nil, type: String) -> CustomerChatSession {
        // Initialize and return a CustomerChatSession
        let sessionOptions = options ?? ChatSessionOptions(region: AWSRegionType(rawValue: (globalConfig?.region)!.rawValue) ?? .USWest2)
        let session = CustomerChatSession(chatDetails: chatDetails, options: sessionOptions, type: type)
        self.currentSession = session
        return session
    }
    
    // Additional utility methods...
}
