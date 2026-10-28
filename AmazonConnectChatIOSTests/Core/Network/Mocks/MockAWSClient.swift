// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAWSClient: AWSClient {
    var createParticipantConnectionResult: Result<ConnectionDetails, Error>?
    var disconnectParticipantConnectionResult: Result<DisconnectParticipantOutput, Error>?
    var sendMessageResult: Result<SendMessageOutput, Error>?
    var sendEventResult: Result<SendEventOutput, Error>?
    var getTranscriptResult: Result<GetTranscriptOutput, Error>?
    var startAttachmentUploadResult: Result<StartAttachmentUploadOutput, Error>?
    var completeAttachmentUploadResult: Result<CompleteAttachmentUploadOutput, Error>?
    var getAttachmentResult: Result<GetAttachmentOutput, Error>?
    var describeViewResult: Result<DescribeViewOutput, Error>?
    var numTypingEventCalled: Int = 0
    var numGetTranscriptCalled: Int = 0

    var lastGetTranscriptArgs: GetTranscriptInput?

    override func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
        if let result = createParticipantConnectionResult {
            completion(result)
        }
    }

    override func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<DisconnectParticipantOutput, Error>) -> Void) {
        if let result = disconnectParticipantConnectionResult {
            completion(result)
        }
    }

    override func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<SendMessageOutput, Error>) -> Void) {
        if let result = sendMessageResult {
            completion(result)
        }
    }

    override func sendEvent(connectionToken: String, contentType: ContentType, content: String, completion: @escaping (Result<SendEventOutput, Error>) -> Void) {
        if contentType == .typing {
            numTypingEventCalled += 1
        }
        if let result = sendEventResult {
            completion(result)
        }
    }

    override func getTranscript(getTranscriptArgs: GetTranscriptInput, completion: @escaping (Result<GetTranscriptOutput, Error>) -> Void) {
        numGetTranscriptCalled += 1
        lastGetTranscriptArgs = getTranscriptArgs
        if let result = getTranscriptResult {
            completion(result)
        }
    }

    override func startAttachmentUpload(connectionToken: String, contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<StartAttachmentUploadOutput, Error>) -> Void) {
        if let result = startAttachmentUploadResult {
            completion(result)
        }
    }

    override func completeAttachmentUpload(connectionToken: String, attachmentIds: [String], completion: @escaping (Result<CompleteAttachmentUploadOutput, Error>) -> Void) {
        if let result = completeAttachmentUploadResult {
            completion(result)
        }
    }

    override func getAttachment(connectionToken: String, attachmentId: String, completion: @escaping (Result<GetAttachmentOutput, Error>) -> Void) {
        if let result = getAttachmentResult {
            completion(result)
        }
    }

    override func describeView(connectionToken: String, viewToken: String, completion: @escaping (Result<DescribeViewOutput, Error>) -> Void) {
        if let result = describeViewResult {
            completion(result)
        }
    }
}
