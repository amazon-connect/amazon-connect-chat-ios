//
//  AWSClient.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation
import AWSConnectParticipant
import AWSCore

protocol AWSClientProtocol {
    func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void)
    func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<Bool, Error>) -> Void)
}

class AWSClient : AWSClientProtocol {
    static let shared = AWSClient()
    
    private var connectParticipantClient: AWSConnectParticipant?
    private var region: AWSRegionType = Constants.DEFAULT_REGION
    
    private init() {}

    func configure(with config: GlobalConfig) {
        
        // AWS service initialization with empty credentials as placeholders
        let credentials = AWSStaticCredentialsProvider(accessKey: "", secretKey: "")
        
        self.region = AWSRegionType(rawValue: config.region.rawValue) ?? Constants.DEFAULT_REGION
        
        let participantService = AWSServiceConfiguration(region: self.region, credentialsProvider: credentials)
        
        AWSConnectParticipant.register(with: participantService!, forKey: Constants.AWSConnectParticipantKey)
        self.connectParticipantClient = AWSConnectParticipant(forKey: Constants.AWSConnectParticipantKey)
    }
    
    func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
        guard let request = AWSConnectParticipantCreateParticipantConnectionRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }
        request.participantToken = participantToken
        request.types = Constants.ACPSRequestTypes
        
        connectParticipantClient?.createParticipantConnection(request).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask<AWSConnectParticipantCreateParticipantConnectionResponse>) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else if let result = task.result, let websocketUrl = result.websocket?.url, let connectionToken = result.connectionCredentials?.connectionToken {
                let details = ConnectionDetails(websocketUrl: websocketUrl, connectionToken: connectionToken, expiry: nil)
                completion(.success(details))
            } else {
                completion(.failure(AWSClientError.unknownError))
            }
            return nil
        })
    }
    
    func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let request = AWSConnectParticipantDisconnectParticipantRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }
        request.connectionToken = connectionToken
        
        connectParticipantClient?.disconnectParticipant(request).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
            return nil
        })
    }
    
    // Potential additional AWS SDK interactions...
    
    enum AWSClientError: Error {
        case requestCreationFailed
        case unknownError
        // Define additional error cases as necessary
    }
}
