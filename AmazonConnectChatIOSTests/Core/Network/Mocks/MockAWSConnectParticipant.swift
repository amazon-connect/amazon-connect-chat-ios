// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAWSConnectParticipant: AWSConnectParticipantProtocol {
    var createParticipantConnectionResult: Result<AWSConnectParticipantCreateParticipantConnectionResponse, Error>?
    var disconnectParticipantResult: Result<AnyObject?, Error>?
    var sendMessageResult: Result<AnyObject?, Error>?
    var sendEventResult: Result<AnyObject?, Error>?
    var getTranscriptResult: Result<AWSConnectParticipantGetTranscriptResponse, Error>?
    var startAttachmentUploadResult: Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>?
    var completeAttachmnetUploadResult: Result<AWSConnectParticipantCompleteAttachmentUploadResponse, Error>?
    var getAttachmentResult: Result<AWSConnectParticipantGetAttachmentResponse, Error>?
    
    func createParticipantConnection(_ request: AWSConnectParticipantCreateParticipantConnectionRequest?) -> AWSTask<AWSConnectParticipantCreateParticipantConnectionResponse> {
        let taskCompletionSource = AWSTaskCompletionSource<AWSConnectParticipantCreateParticipantConnectionResponse>()
        if request == nil {
            taskCompletionSource.set(error: AWSClient.AWSClientError.requestCreationFailed)
        } else if let result = createParticipantConnectionResult {
            switch result {
            case .success(let response):
                taskCompletionSource.set(result: response)
            case .failure(let error):
                taskCompletionSource.set(error: error)
            }
        } else {
            taskCompletionSource.set(error: MockError.unexpected)
        }
        return taskCompletionSource.task
    }
    
    func disconnectParticipant(_ request: AWSConnectParticipantDisconnectParticipantRequest?) -> AWSTask<AnyObject> {
        let taskCompletionSource = AWSTaskCompletionSource<AnyObject>()
        if let result = disconnectParticipantResult {
            switch result {
            case .success(let response):
                taskCompletionSource.set(result: response)
            case .failure(let error):
                taskCompletionSource.set(error: error)
            }
        } else if request == nil {
            taskCompletionSource.set(error: AWSClient.AWSClientError.requestCreationFailed)
        } else {
            taskCompletionSource.set(error: MockError.unexpected)
        }
        return taskCompletionSource.task
    }
    
    func sendMessage(_ request: AWSConnectParticipantSendMessageRequest?) -> AWSTask<AnyObject> {
        let taskCompletionSource = AWSTaskCompletionSource<AnyObject>()
        if let result = sendMessageResult {
            switch result {
            case .success(let response):
                taskCompletionSource.set(result: response)
            case .failure(let error):
                taskCompletionSource.set(error: error)
            }
        } else if request == nil {
            taskCompletionSource.set(error: AWSClient.AWSClientError.requestCreationFailed)
        } else {
            taskCompletionSource.set(error: MockError.unexpected)
        }
        return taskCompletionSource.task
    }
    
    func sendEvent(_ request: AWSConnectParticipantSendEventRequest?) -> AWSTask<AnyObject> {
        let taskCompletionSource = AWSTaskCompletionSource<AnyObject>()
        if let result = sendEventResult {
            switch result {
            case .success(let response):
                taskCompletionSource.set(result: response)
            case .failure(let error):
                taskCompletionSource.set(error: error)
            }
        } else if request == nil {
            taskCompletionSource.set(error: AWSClient.AWSClientError.requestCreationFailed)
        } else {
            taskCompletionSource.set(error: MockError.unexpected)
        }
        return taskCompletionSource.task
    }
    
    func getTranscript(_ request: AWSConnectParticipantGetTranscriptRequest?) -> AWSTask<AWSConnectParticipantGetTranscriptResponse> {
        let taskCompletionSource = AWSTaskCompletionSource<AWSConnectParticipantGetTranscriptResponse>()
        if let result = getTranscriptResult {
            switch result {
            case .success(let response):
                taskCompletionSource.set(result: response)
            case .failure(let error):
                taskCompletionSource.set(error: error)
            }
        } else if request == nil {
            taskCompletionSource.set(error: AWSClient.AWSClientError.requestCreationFailed)
        } else {
            taskCompletionSource.set(error: MockError.unexpected)
        }
        return taskCompletionSource.task
    }
    
    func startAttachmentUpload(_ request: AWSConnectParticipantStartAttachmentUploadRequest?) -> AWSTask<AWSConnectParticipantStartAttachmentUploadResponse> {
        let taskCompletionSource = AWSTaskCompletionSource<AWSConnectParticipantStartAttachmentUploadResponse>()
        if let result = startAttachmentUploadResult {
            switch result {
            case .success(let response):
                taskCompletionSource.set(result: response)
            case .failure(let error):
                taskCompletionSource.set(error: error)
            }
        } else if request == nil {
            taskCompletionSource.set(error: AWSClient.AWSClientError.requestCreationFailed)
        } else {
            taskCompletionSource.set(error: MockError.unexpected)
        }
        return taskCompletionSource.task
    }
    
    func completeAttachmentUpload(_ request: AWSConnectParticipantCompleteAttachmentUploadRequest?) -> AWSTask<AWSConnectParticipantCompleteAttachmentUploadResponse> {
        let taskCompletionSource = AWSTaskCompletionSource<AWSConnectParticipantCompleteAttachmentUploadResponse>()
        if let result = completeAttachmnetUploadResult {
            switch result {
            case .success(let response):
                taskCompletionSource.set(result: response)
            case .failure(let error):
                taskCompletionSource.set(error: error)
            }
        } else if request == nil {
            taskCompletionSource.set(error: AWSClient.AWSClientError.requestCreationFailed)
        } else {
            taskCompletionSource.set(error: MockError.unexpected)
        }
        return taskCompletionSource.task
    }
    
    func getAttachment(_ request: AWSConnectParticipantGetAttachmentRequest?) -> AWSTask<AWSConnectParticipantGetAttachmentResponse> {
        let taskCompletionSource = AWSTaskCompletionSource<AWSConnectParticipantGetAttachmentResponse>()
        if let result = getAttachmentResult {
            switch result {
            case .success(let response):
                taskCompletionSource.set(result: response)
            case .failure(let error):
                taskCompletionSource.set(error: error)
            }
        } else if request == nil {
            taskCompletionSource.set(error: AWSClient.AWSClientError.requestCreationFailed)
        } else {
            taskCompletionSource.set(error: MockError.unexpected)
        }
        return taskCompletionSource.task
    }
    
    enum MockError: Error {
        case unexpected
    }
}
