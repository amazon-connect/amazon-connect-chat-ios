// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAWSConnectParticipant: AWSConnectParticipantProtocol {
    var createParticipantConnectionResult: Result<AWSConnectParticipantCreateParticipantConnectionResponse, Error>?
    var disconnectParticipantResult: Result<AnyObject?, Error>?
    var sendMessageResult: Result<AnyObject?, Error>?
    var sendEventResult: Result<AnyObject?, Error>?
    var getTranscriptResult: Result<AWSConnectParticipantGetTranscriptResponse, Error>?
    
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
    
    enum MockError: Error {
        case unexpected
    }
}
