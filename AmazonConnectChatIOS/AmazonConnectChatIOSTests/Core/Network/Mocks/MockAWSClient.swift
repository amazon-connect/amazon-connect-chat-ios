// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAWSClient: AWSClientProtocol {
    var createParticipantConnectionResult: Result<ConnectionDetails, Error>?
    var disconnectParticipantConnectionResult: Result<Bool, Error>?
    var sendMessageResult: Result<Bool, Error>?
    var sendEventResult: Result<Bool, Error>?
    var getTranscriptResult: Result<AWSConnectParticipantGetTranscriptResponse, Error>?
    var startAttachmentUploadResult: Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>?
    var completeAttachmentUploadResult: Result<AWSConnectParticipantCompleteAttachmentUploadResponse, Error>?
    var getAttachmentResult: Result<AWSConnectParticipantGetAttachmentResponse, Error>?
    var numTypingEventCalled: Int = 0

    func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
        if let result = createParticipantConnectionResult {
            completion(result)
        }
    }
    
    func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if let result = disconnectParticipantConnectionResult {
            completion(result)
        }
    }
    
    func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if let result = sendMessageResult {
            completion(result)
        }
    }
    
    func sendEvent(connectionToken: String, contentType: ContentType, content: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if contentType == .typing {
            numTypingEventCalled += 1
        }
        if let result = sendEventResult {
            completion(result)
        }
    }
    
    func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<AWSConnectParticipantGetTranscriptResponse, Error>) -> Void) {
        if let result = getTranscriptResult {
            completion(result)
        }
    }
    
    func startAttachmentUpload(connectionToken: String, contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>) -> Void) {
        if let result = startAttachmentUploadResult {
            completion(result)
        }
    }

    func completeAttachmentUpload(connectionToken: String, attachmentIds: [String], completion: @escaping (Result<AWSConnectParticipantCompleteAttachmentUploadResponse, Error>) -> Void) {
        if let result = completeAttachmentUploadResult {
            completion(result)
        }
    }
    
    func getAttachment(connectionToken: String, attachmentId: String, completion: @escaping (Result<AWSConnectParticipantGetAttachmentResponse, Error>) -> Void) {
        if let result = getAttachmentResult {
            completion(result)
        }
    }
}

