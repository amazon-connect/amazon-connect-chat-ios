// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0


import Foundation
import AWSConnectParticipant
import AWSCore

/// Protocol defining the AWS client operations.
public protocol AWSClientProtocol {
    /// Creates a new participant connection.
    /// - Parameters:
    ///   - participantToken: The token for the participant to identify.
    ///   - completion: Completion handler to handle the connection details or error.
    func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void)
    
    /// Disconnects an existing participant connection.
    /// - Parameters:
    ///   - connectionToken: The token for the connection to be disconnected.
    ///   - completion: Completion handler to handle the success status or error.
    func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<AWSConnectParticipantDisconnectParticipantResponse, Error>) -> Void)
    
    /// Sends a message.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the message is sent.
    ///   - message: The message text to be sent.
    ///   - completion: Completion handler to handle the success status or error.
    func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<AWSConnectParticipantSendMessageResponse, Error>) -> Void)
    
    /// Sends an event..
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - contentType: The type of content being sent.
    ///   - content: The content string to be sent.
    ///   - completion: Completion handler to handle the success status or error.
    func sendEvent(connectionToken: String, contentType: ContentType, content: String, completion: @escaping (Result<AWSConnectParticipantSendEventResponse, Error>) -> Void)
    
    /// Requests a pre-signed S3 URL with authentication headers used to upload a given file to S3.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - contentType: Describes the MIME file type of the attachment.
    ///   - attachmentName: A case-sensitive name of the attachment being uploaded.
    ///   - attachmentSizeInBytes: The size of the attachment in bytes.
    ///   - completion: Completion handler to handle the success status or error.
    func startAttachmentUpload(connectionToken: String, contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>) -> Void)

    /// Communicates with the Connect Participant backend to signal that the file has been uploaded successfully.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - attachmentIds: A list of unique identifiers for the attachments.
    ///   - completion: Completion handler to handle the success status or error.
    func completeAttachmentUpload(connectionToken: String, attachmentIds: [String], completion: @escaping (Result<AWSConnectParticipantCompleteAttachmentUploadResponse, Error>) -> Void)
    
    /// Retrieves a download URL for the attachment defined by the attachmentId.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - attachmentId: A unique identifier for the attachment.
    ///   - completion: Completion handler to handle the success status or error.
    func getAttachment(connectionToken: String, attachmentId: String, completion: @escaping (Result<AWSConnectParticipantGetAttachmentResponse, Error>) -> Void)
  
    /// Requests the chat transcript.
    /// - Parameters:
    ///   - getTranscriptArgs: arguments for the get transcript request.
    ///   - completion: Completion handler to handle the success status or error.
    func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<AWSConnectParticipantGetTranscriptResponse, Error>) -> Void)
}

/// AWSClient manages the interactions with AWS Connect Participant service.
public class AWSClient: AWSClientProtocol {
    /// Shared instance of AWSClient.
    public static let shared = AWSClient()
    
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
    
    var startAttachmentUploadRequest: () -> AWSConnectParticipantStartAttachmentUploadRequest? = {
        AWSConnectParticipantStartAttachmentUploadRequest()
    }
    
    var completeAttachmentUploadRequest: () -> AWSConnectParticipantCompleteAttachmentUploadRequest? = {
        AWSConnectParticipantCompleteAttachmentUploadRequest()
    }
    
    var getAttachmentRequest: () -> AWSConnectParticipantGetAttachmentRequest? = {
        AWSConnectParticipantGetAttachmentRequest()
    }
    
    private init() {}
    
    
    /// Configures the client with global configuration settings.
    /// - Parameter config: Global configuration settings.
    func configure(with config: GlobalConfig, participantClient: AWSConnectParticipantProtocol? = nil) {
        // AWS service initialization with empty credentials as placeholders
        let credentials = AWSStaticCredentialsProvider(accessKey: "", secretKey: "")
        
        self.region = AWSRegionType(rawValue: config.region.rawValue) ?? Constants.DEFAULT_REGION
        
        let participantService = AWSServiceConfiguration(region: self.region, credentialsProvider: credentials)
        participantService?.addUserAgentProductToken("AmazonConnect-Mobile Chat-iOS SDK/\(CommonUtils.getLibraryVersion())")
        
        AWSConnectParticipant.register(with: participantService!, forKey: Constants.AWSConnectParticipantKey)
        
        if let participantClient = participantClient {
            self.connectParticipantClient = participantClient
        } else {
            self.connectParticipantClient = AWSConnectParticipantAdapter(participant: AWSConnectParticipant(forKey: Constants.AWSConnectParticipantKey))
        }
    }
    
    /// Creates a connection for a participant identified by a token.
    public func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
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
    public func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<AWSConnectParticipantDisconnectParticipantResponse, Error>) -> Void) {
        guard let request = disconnectParticipantRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }
        request.connectionToken = connectionToken
        
        connectParticipantClient?.disconnectParticipant(request).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else if let result = task.result as? AWSConnectParticipantDisconnectParticipantResponse {
                completion(.success(result))
            } else {
                let error = NSError(domain: "AWSClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response from disconnectParticipant"])
                completion(.failure(error))
            }
            return nil
        })
    }
    
    /// Sends a message using a connection token.
    public func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<AWSConnectParticipantSendMessageResponse, Error>) -> Void) {
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
            } else if let result = task.result as? AWSConnectParticipantSendMessageResponse {
                completion(.success(result))
            } else {
                let error = NSError(domain: "AWSClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response from sendMessage"])
                completion(.failure(error))
            }
            return nil
        })
    }
    
    /// Sends an event using a connection token.
    public func sendEvent(connectionToken: String, contentType: ContentType, content: String = "", completion: @escaping (Result<AWSConnectParticipantSendEventResponse, Error>) -> Void) {
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
            } else if let result = task.result as? AWSConnectParticipantSendEventResponse {
                completion(.success(result))
            } else {
                let error = NSError(domain: "AWSClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response from sendEvent"])
                completion(.failure(error))
            }
            return nil
        })
    }
    
    public func startAttachmentUpload(connectionToken: String, contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>) -> Void) {
        guard let request = AWSConnectParticipantStartAttachmentUploadRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }
        
        request.connectionToken = connectionToken
        request.contentType = contentType
        request.attachmentName = attachmentName
        request.attachmentSizeInBytes = NSNumber(value: attachmentSizeInBytes)
        
        connectParticipantClient?.startAttachmentUpload(request).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask<AWSConnectParticipantStartAttachmentUploadResponse>) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else if let result = task.result {
                completion(.success(result))
            } else {
                completion(.failure(AWSClientError.unknownError))
            }
            return nil
        })
    }
    
    public func completeAttachmentUpload(connectionToken: String, attachmentIds: [String], completion: @escaping (Result<AWSConnectParticipantCompleteAttachmentUploadResponse, Error>) -> Void) {
        guard let request = AWSConnectParticipantCompleteAttachmentUploadRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }
        
        request.connectionToken = connectionToken
        request.attachmentIds = attachmentIds
        
        connectParticipantClient?.completeAttachmentUpload(request).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else if let result = task.result {
                completion(.success(result))
            } else {
                completion(.failure(AWSClientError.unknownError))
            }
            return nil
        })
    }
    
    public func getAttachment(connectionToken: String, attachmentId: String, completion: @escaping (Result<AWSConnectParticipantGetAttachmentResponse, Error>) -> Void) {
        guard let request = AWSConnectParticipantGetAttachmentRequest() else {
            completion(.failure(AWSClientError.requestCreationFailed))
            return
        }
        
        request.connectionToken = connectionToken
        request.attachmentId = attachmentId
        
        connectParticipantClient?.getAttachment(request).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask<AWSConnectParticipantGetAttachmentResponse>) -> AnyObject? in
            if let error = task.error {
                completion(.failure(error))
            } else if let result = task.result {
                completion(.success(result))
            } else {
                completion(.failure(AWSClientError.unknownError))
            }
            return nil
        })
    }
    
    public func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<AWSConnectParticipantGetTranscriptResponse, Error>) -> Void) {
        connectParticipantClient?.getTranscript(getTranscriptArgs).continueWith { (task) -> AnyObject? in
            if let error = task.error {
                SDKLogger.logger.logError("Error in getting transcript: \(error.localizedDescription)")
                completion(.failure(error))
                return nil
            }
            
            guard let result = task.result, let transcriptItems = result.transcript else {
                SDKLogger.logger.logError("No result or incorrect type from getTranscript")
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
