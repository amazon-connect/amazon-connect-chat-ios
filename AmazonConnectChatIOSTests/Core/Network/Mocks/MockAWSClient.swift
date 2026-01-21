// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAWSClient: AWSClient {
    var createParticipantConnectionResult: Result<ConnectionDetails, Error>?
    var disconnectParticipantConnectionResult: Result<AWSConnectParticipantDisconnectParticipantResponse, Error>?
    var sendMessageResult: Result<AWSConnectParticipantSendMessageResponse, Error>?
    var sendEventResult: Result<AWSConnectParticipantSendEventResponse, Error>?
    var getTranscriptResult: Result<AWSConnectParticipantGetTranscriptResponse, Error>?
    var startAttachmentUploadResult: Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>?
    var completeAttachmentUploadResult: Result<AWSConnectParticipantCompleteAttachmentUploadResponse, Error>?
    var getAttachmentResult: Result<AWSConnectParticipantGetAttachmentResponse, Error>?
    var describeViewResult: Result<AWSConnectParticipantDescribeViewResponse, Error>?
    var numTypingEventCalled: Int = 0
    var numGetTranscriptCalled: Int = 0

    override func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
        if let result = createParticipantConnectionResult {
            completion(result)
        }
    }
    
    override func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<AWSConnectParticipantDisconnectParticipantResponse, Error>) -> Void) {
        if let result = disconnectParticipantConnectionResult {
            completion(result)
        }
    }
    
    override func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<AWSConnectParticipantSendMessageResponse, Error>) -> Void) {
        if let result = sendMessageResult {
            completion(result)
        }
    }
    
    override func sendEvent(connectionToken: String, contentType: ContentType, content: String, completion: @escaping (Result<AWSConnectParticipantSendEventResponse, Error>) -> Void) {
        if contentType == .typing {
            numTypingEventCalled += 1
        }
        if let result = sendEventResult {
            completion(result)
        }
    }
    
    override func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<AWSConnectParticipantGetTranscriptResponse, Error>) -> Void) {
        numGetTranscriptCalled += 1
        if let result = getTranscriptResult {
            completion(result)
        }
    }
    
    override func startAttachmentUpload(connectionToken: String, contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>) -> Void) {
        if let result = startAttachmentUploadResult {
            completion(result)
        }
    }

    override func completeAttachmentUpload(connectionToken: String, attachmentIds: [String], completion: @escaping (Result<AWSConnectParticipantCompleteAttachmentUploadResponse, Error>) -> Void) {
        if let result = completeAttachmentUploadResult {
            completion(result)
        }
    }
    
    override func getAttachment(connectionToken: String, attachmentId: String, completion: @escaping (Result<AWSConnectParticipantGetAttachmentResponse, Error>) -> Void) {
        if let result = getAttachmentResult {
            completion(result)
        }
    }
    
    override func describeView(connectionToken: String, viewToken: String, completion: @escaping (Result<AWSConnectParticipantDescribeViewResponse, Error>) -> Void) {
        if let result = describeViewResult {
            completion(result)
        }
    }
}

