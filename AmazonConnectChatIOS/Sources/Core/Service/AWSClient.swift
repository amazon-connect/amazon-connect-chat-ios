//
//  AWSClient.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/3/24.
//

import Foundation
import AWSConnectParticipant
import Foundation
import AWSConnectParticipant
import AWSCore

protocol AWSClientProtocol {
    func createParticipantConnection(participantToken: String, completion: @escaping (Bool, String?, String?, Error?) -> Void)
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
    
    func createParticipantConnection(participantToken: String, completion: @escaping (Bool, String?, String?, Error?) -> Void) {
        guard let request = AWSConnectParticipantCreateParticipantConnectionRequest() else {
            completion(false, nil, nil, AWSClientError.requestCreationFailed)
            return
        }
        request.participantToken = participantToken
        request.types = Constants.ACPSRequestTypes
        
        self.connectParticipantClient?.createParticipantConnection(request).continueWith { (task: AWSTask<AWSConnectParticipantCreateParticipantConnectionResponse>) -> AnyObject? in
            DispatchQueue.main.async {
                if let error = task.error {
                    completion(false, nil, nil, error)
                } else if let result = task.result, let websocketUrl = result.websocket?.url, let connectionToken = result.connectionCredentials?.connectionToken {
                    // Connection established successfully
                    completion(true, websocketUrl, connectionToken, nil)
                } else {
                    completion(false, nil, nil, AWSClientError.unknownError)
                }
            }
            return nil
        }
    }
    
    // Potential additional AWS SDK interactions...
    
    enum AWSClientError: Error {
        case requestCreationFailed
        case unknownError
        // Define additional error cases as necessary
    }
}
