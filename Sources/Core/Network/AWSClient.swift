// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0


import Foundation
import AWSConnectParticipant
import AWSSDKIdentity

/// AWSClient manages the interactions with AWS Connect Participant service.
/// Subclass this to selectively override specific API methods while inheriting default behavior for others.
open class AWSClient {
    /// Shared instance of AWSClient.
    public static let shared = AWSClient()

    /// AWS Connect Participant Client
    var connectParticipantClient: AWSConnectParticipantProtocol?

    /// AWS region for the service configuration.
    var region: Region = Constants.DEFAULT_REGION

    // ConnectParticipant authorizes requests with the participantToken/connectionToken in the
    // X-Amz-Bearer header and does not use SigV4, so requests are sent unsigned, as they were with
    // the AWS Mobile SDK. The CRT signer rejects empty credentials, so signing is skipped through the
    // noAuth scheme rather than run with placeholders. The placeholder resolver is still set so the
    // client never builds the default credential chain, which could otherwise inspect the
    // environment, shared config, or metadata services on a customer device.
    static let placeholderCredentials = AWSCredentialIdentity(accessKey: "", secret: "")

    public init() {}

    /// Configures the client with global configuration settings.
    /// - Parameter config: Global configuration settings.
    public func configure(with config: GlobalConfig) {
        self.configure(with: config, participantClient: nil)
    }

    /// Internal configuration method with participant client injection for testing
    func configure(with config: GlobalConfig, participantClient: AWSConnectParticipantProtocol?) {
        self.region = config.region

        if let participantClient = participantClient {
            self.connectParticipantClient = participantClient
            return
        }

        do {
            let clientConfig = try Self.makeClientConfig(region: self.region)
            self.connectParticipantClient = AWSConnectParticipantAdapter(
                client: ConnectParticipantClient(config: clientConfig)
            )
        } catch {
            SDKLogger.logger.logError("Failed to configure ConnectParticipant client: \(error.localizedDescription)")
            self.connectParticipantClient = nil
        }
    }

    static func makeClientConfig(region: Region) throws -> ConnectParticipantClient.ConnectParticipantClientConfig {
        var clientConfig = try ConnectParticipantClient.ConnectParticipantClientConfig(region: region.rawValue)
        clientConfig.awsCredentialIdentityResolver = StaticAWSCredentialIdentityResolver(Self.placeholderCredentials)
        clientConfig.authSchemeResolver = NoAuthSchemeResolver()
        clientConfig.appID = Constants.userAgentAppID()
        // The appID above is the SDK-supported attribution field, but it sanitizes the legacy
        // product token. Wrap the engine so requests also carry the exact 2.x token.
        clientConfig.httpClientEngine = UserAgentProductTokenHTTPClient(
            wrapping: clientConfig.httpClientEngine,
            productToken: Constants.userAgentProductToken()
        )
        return clientConfig
    }

    /// Creates a connection for a participant identified by a token.
    /// - Parameters:
    ///   - participantToken: The token for the participant to identify.
    ///   - completion: Completion handler to handle the connection details or error.
    open func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
        var input = CreateParticipantConnectionInput()
        input.participantToken = participantToken
        input.type = Constants.ACPSRequestTypes

        perform({ try await $0.createParticipantConnection(input) }) { result in
            switch result {
            case .success(let output):
                if let websocketUrl = output.websocket?.url,
                   let connectionToken = output.connectionCredentials?.connectionToken {
                    let details = ConnectionDetails(websocketUrl: websocketUrl, connectionToken: connectionToken, expiry: nil)
                    completion(.success(details))
                } else {
                    completion(.failure(AWSClientError.invalidConnectionResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Disconnects a participant connection using a connection token.
    /// - Parameters:
    ///   - connectionToken: The token for the connection to be disconnected.
    ///   - completion: Completion handler to handle the success status or error.
    open func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<DisconnectParticipantOutput, Error>) -> Void) {
        var input = DisconnectParticipantInput()
        input.connectionToken = connectionToken

        perform({ try await $0.disconnectParticipant(input) }, then: completion)
    }

    /// Sends a message using a connection token.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the message is sent.
    ///   - contentType: The type of content being sent.
    ///   - message: The message text to be sent.
    ///   - completion: Completion handler to handle the success status or error.
    open func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<SendMessageOutput, Error>) -> Void) {
        var input = SendMessageInput()
        input.connectionToken = connectionToken
        input.content = message
        input.contentType = contentType.rawValue

        perform({ try await $0.sendMessage(input) }, then: completion)
    }

    /// Sends an event using a connection token.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - contentType: The type of content being sent.
    ///   - content: The content string to be sent.
    ///   - completion: Completion handler to handle the success status or error.
    open func sendEvent(connectionToken: String, contentType: ContentType, content: String = "", completion: @escaping (Result<SendEventOutput, Error>) -> Void) {
        var input = SendEventInput()
        input.connectionToken = connectionToken
        input.contentType = contentType.rawValue
        // The service rejects an empty Content string. The AWS Mobile SDK left empty strings out of
        // the request body, so events without content, such as typing, must omit the field.
        input.content = content.isEmpty ? nil : content

        perform({ try await $0.sendEvent(input) }, then: completion)
    }

    /// Requests a pre-signed S3 URL with authentication headers used to upload a given file to S3.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - contentType: Describes the MIME file type of the attachment.
    ///   - attachmentName: A case-sensitive name of the attachment being uploaded.
    ///   - attachmentSizeInBytes: The size of the attachment in bytes.
    ///   - completion: Completion handler to handle the success status or error.
    open func startAttachmentUpload(connectionToken: String, contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<StartAttachmentUploadOutput, Error>) -> Void) {
        var input = StartAttachmentUploadInput()
        input.connectionToken = connectionToken
        input.contentType = contentType
        input.attachmentName = attachmentName
        input.attachmentSizeInBytes = attachmentSizeInBytes

        perform({ try await $0.startAttachmentUpload(input) }, then: completion)
    }

    /// Communicates with the Connect Participant backend to signal that the file has been uploaded successfully.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - attachmentIds: A list of unique identifiers for the attachments.
    ///   - completion: Completion handler to handle the success status or error.
    open func completeAttachmentUpload(connectionToken: String, attachmentIds: [String], completion: @escaping (Result<CompleteAttachmentUploadOutput, Error>) -> Void) {
        var input = CompleteAttachmentUploadInput()
        input.connectionToken = connectionToken
        input.attachmentIds = attachmentIds

        perform({ try await $0.completeAttachmentUpload(input) }, then: completion)
    }

    /// Retrieves a download URL for the attachment defined by the attachmentId.
    /// - Parameters:
    ///   - connectionToken: The token for the connection through which the event is sent.
    ///   - attachmentId: A unique identifier for the attachment.
    ///   - completion: Completion handler to handle the success status or error.
    open func getAttachment(connectionToken: String, attachmentId: String, completion: @escaping (Result<GetAttachmentOutput, Error>) -> Void) {
        var input = GetAttachmentInput()
        input.connectionToken = connectionToken
        input.attachmentId = attachmentId

        perform({ try await $0.getAttachment(input) }, then: completion)
    }

    /// Requests the chat transcript.
    /// - Parameters:
    ///   - getTranscriptArgs: arguments for the get transcript request.
    ///   - completion: Completion handler to handle the success status or error.
    open func getTranscript(getTranscriptArgs: GetTranscriptInput, completion: @escaping (Result<GetTranscriptOutput, Error>) -> Void) {
        perform({ try await $0.getTranscript(getTranscriptArgs) }) { result in
            switch result {
            case .success(let output):
                guard output.transcript != nil else {
                    SDKLogger.logger.logError("No result or incorrect type from getTranscript")
                    let error = NSError(domain: "aws.amazon.com", code: 1001, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to obtain transcript: No result or incorrect type returned from getTranscript."
                    ])
                    completion(.failure(error))
                    return
                }
                completion(.success(output))
            case .failure(let error):
                SDKLogger.logger.logError("Error in getting transcript: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    /// Retrieves a view resource object containing metadata and content necessary to render the view.
    /// - Parameters:
    ///   - connectionToken: The token for the connection.
    ///   - viewToken: An encrypted token originating from the interactive message of a ShowView block operation.
    ///   - completion: Completion handler to handle the success status or error.
    open func describeView(connectionToken: String, viewToken: String, completion: @escaping (Result<DescribeViewOutput, Error>) -> Void) {
        var input = DescribeViewInput()
        input.connectionToken = connectionToken
        input.viewToken = viewToken

        perform({ try await $0.describeView(input) }, then: completion)
    }

    /// Awaits an operation on the participant client and delivers the outcome on the main queue.
    /// - Parameters:
    ///   - operation: The operation to run against the configured participant client.
    ///   - handler: Handler invoked on the main queue with the operation's result.
    private func perform<Output>(
        _ operation: @escaping (AWSConnectParticipantProtocol) async throws -> Output,
        then handler: @escaping (Result<Output, Error>) -> Void
    ) {
        guard let client = connectParticipantClient else {
            DispatchQueue.main.async { handler(.failure(AWSClientError.failedToInitializeParticipantClient)) }
            return
        }

        Task {
            do {
                let output = try await operation(client)
                DispatchQueue.main.async { handler(.success(output)) }
            } catch {
                DispatchQueue.main.async { handler(.failure(error)) }
            }
        }
    }

    /// Enum for client-specific errors.
    enum AWSClientError: LocalizedError, Equatable {
        case invalidConnectionResponse
        case failedToInitializeParticipantClient

        var errorDescription: String? {
            switch self {
            case .invalidConnectionResponse:
                return "ConnectParticipant returned a response without a WebSocket URL or connection token."
            case .failedToInitializeParticipantClient:
                return "The ConnectParticipant client has not been configured."
            }
        }
    }
}
