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
    func sendMessage(connectionToken: String, message: String, completion: @escaping (Result<Bool, Error>) -> Void)
    func sendEvent(connectionToken: String, contentType: ContentType,content: String, completion: @escaping (Result<Bool, Error>) -> Void)
    func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<[AWSConnectParticipantItem], Error>) -> Void)
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
    
    func sendMessage(connectionToken: String, message: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let request = AWSConnectParticipantSendMessageRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }
        request.connectionToken = connectionToken
        request.content = message
        request.contentType = "text/plain"
        
        connectParticipantClient?.sendMessage(request).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
            return nil
        })
    }
    
    func sendEvent(connectionToken: String, contentType: ContentType, content: String = "", completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let request = AWSConnectParticipantSendEventRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }

        request.connectionToken = connectionToken
        request.contentType = contentType.rawValue
        request.content = content
        
        connectParticipantClient?.sendEvent(request).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
            return nil
        })
    }
    
    func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<[AWSConnectParticipantItem], Error>) -> Void) {
        connectParticipantClient?.getTranscript(getTranscriptArgs).continueWith { (task) -> AnyObject? in
            if let error = task.error {
                print("Error in getting transcript: \(error.localizedDescription)")
                completion(.failure(error))
                return nil
            }
            
            guard let result = task.result, let transcriptItems = result.transcript else {
                print("No result or incorrect type from getTranscript")
                let error = NSError(domain: "aws.amazon.com", code: 1001, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to obtain transcript: No result or incorrect type returned from getTranscript."
                ])
                completion(.failure(error))  // Call completion even if there's no result
                return nil
            }
            completion(.success(transcriptItems))
            
            return nil
        }
    }
    
    enum AWSClientError: Error {
        case requestCreationFailed
        case unknownError
        // Define additional error cases as necessary
    }
}
