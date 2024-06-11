// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0


import Foundation
import AWSConnectParticipant
import AWSCore

/// Protocol defining the AWS client operations.
protocol AWSClientProtocol {
    /// Creates a new participant connection.
    /// - Parameters:
    ///   - participantToken: The token for the participant to identify.
    ///   - completion: Completion handler to handle the connection details or error.
    func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void)
    
    /// Disconnects an existing participant connection.
    /// - Parameters:
    ///   - connectionToken: The token for the connection to be disconnected.
    ///   - completion: Completion handler to handle the success status or error.
    func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<Bool, Error>) -> Void)
    
    /// Sends a message.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the message is sent.
    ///   - message: The message text to be sent.
    ///   - completion: Completion handler to handle the success status or error.
    func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<Bool, Error>) -> Void)
    
    /// Sends an event..
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - contentType: The type of content being sent.
    ///   - content: The content string to be sent.
    ///   - completion: Completion handler to handle the success status or error.
    func sendEvent(connectionToken: String, contentType: ContentType, content: String, completion: @escaping (Result<Bool, Error>) -> Void)
    
    func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<AWSConnectParticipantGetTranscriptResponse, Error>) -> Void)
}

/// AWSClient manages the interactions with AWS Connect Participant service.
class AWSClient: AWSClientProtocol {
    /// Shared instance of AWSClient.
    static let shared = AWSClient()
    
    /// AWS Connect Participant Client
    var connectParticipantClient: AWSConnectParticipantProtocol?
    
    /// AWS region for the service configuration.
    var region: AWSRegionType = Constants.DEFAULT_REGION
    
    // Dependency injection for unit tests
    var createParticipantConnectionRequest: () -> AWSConnectParticipantCreateParticipantConnectionRequest? = {
        AWSConnectParticipantCreateParticipantConnectionRequest()
    }
    var disconnectParticipantRequest: () -> AWSConnectParticipantDisconnectParticipantRequest? = {
        AWSConnectParticipantDisconnectParticipantRequest()
    }
    var sendMessageRequest: () -> AWSConnectParticipantSendMessageRequest? = {
        AWSConnectParticipantSendMessageRequest()
    }
    var sendEventRequest: () -> AWSConnectParticipantSendEventRequest? = {
        AWSConnectParticipantSendEventRequest()
    }
    
    private init() {}
    
    
    /// Configures the client with global configuration settings.
    /// - Parameter config: Global configuration settings.
    func configure(with config: GlobalConfig, participantClient: AWSConnectParticipantProtocol? = nil) {
        // AWS service initialization with empty credentials as placeholders
        let credentials = AWSStaticCredentialsProvider(accessKey: "", secretKey: "")
        
        self.region = AWSRegionType(rawValue: config.region.rawValue) ?? Constants.DEFAULT_REGION
        
        let participantService = AWSServiceConfiguration(region: self.region, credentialsProvider: credentials)
        
        AWSConnectParticipant.register(with: participantService!, forKey: Constants.AWSConnectParticipantKey)
        
        if let participantClient = participantClient {
            self.connectParticipantClient = participantClient
        } else {
            self.connectParticipantClient = AWSConnectParticipantAdapter(participant: AWSConnectParticipant(forKey: Constants.AWSConnectParticipantKey))
        }
    }
    
    /// Creates a connection for a participant identified by a token.
    func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
        guard let request = createParticipantConnectionRequest() else {
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
    
    /// Disconnects a participant connection using a connection token.
    func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let request = disconnectParticipantRequest() else {
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
    
    /// Sends a message using a connection token.
    func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let request = sendMessageRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }
        request.connectionToken = connectionToken
        request.content = message
        request.contentType = contentType.rawValue
        
        connectParticipantClient?.sendMessage(request).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
            return nil
        })
    }
    
    /// Sends an event using a connection token.
    func sendEvent(connectionToken: String, contentType: ContentType, content: String = "", completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let request = sendEventRequest() else {
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
    
    func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<AWSConnectParticipantGetTranscriptResponse, Error>) -> Void) {
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
                completion(.failure(error))
                return nil
            }
            completion(.success(result))
            return nil
        }
    }
    
    /// Enum for client-specific errors.
    enum AWSClientError: Error {
        case requestCreationFailed
        case unknownError
        case failedToInitializeParticipantClient
    }
}
