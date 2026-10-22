// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAWSConnectParticipant: AWSConnectParticipantProtocol {
    var createParticipantConnectionResult: Result<CreateParticipantConnectionOutput, Error>?
    var disconnectParticipantResult: Result<DisconnectParticipantOutput, Error>?
    var sendMessageResult: Result<SendMessageOutput, Error>?
    var sendEventResult: Result<SendEventOutput, Error>?
    var getTranscriptResult: Result<GetTranscriptOutput, Error>?
    var startAttachmentUploadResult: Result<StartAttachmentUploadOutput, Error>?
    var completeAttachmnetUploadResult: Result<CompleteAttachmentUploadOutput, Error>?
    var getAttachmentResult: Result<GetAttachmentOutput, Error>?
    var describeViewResult: Result<DescribeViewOutput, Error>?

    // Last input received per operation.
    var lastCreateParticipantConnectionInput: CreateParticipantConnectionInput?
    var lastDisconnectParticipantInput: DisconnectParticipantInput?
    var lastSendMessageInput: SendMessageInput?
    var lastSendEventInput: SendEventInput?
    var lastGetTranscriptInput: GetTranscriptInput?
    var lastStartAttachmentUploadInput: StartAttachmentUploadInput?
    var lastCompleteAttachmentUploadInput: CompleteAttachmentUploadInput?
    var lastGetAttachmentInput: GetAttachmentInput?
    var lastDescribeViewInput: DescribeViewInput?

    func createParticipantConnection(_ input: CreateParticipantConnectionInput) async throws -> CreateParticipantConnectionOutput {
        lastCreateParticipantConnectionInput = input
        return try resolve(createParticipantConnectionResult)
    }

    func disconnectParticipant(_ input: DisconnectParticipantInput) async throws -> DisconnectParticipantOutput {
        lastDisconnectParticipantInput = input
        return try resolve(disconnectParticipantResult)
    }

    func sendMessage(_ input: SendMessageInput) async throws -> SendMessageOutput {
        lastSendMessageInput = input
        return try resolve(sendMessageResult)
    }

    func sendEvent(_ input: SendEventInput) async throws -> SendEventOutput {
        lastSendEventInput = input
        return try resolve(sendEventResult)
    }

    func getTranscript(_ input: GetTranscriptInput) async throws -> GetTranscriptOutput {
        lastGetTranscriptInput = input
        return try resolve(getTranscriptResult)
    }

    func startAttachmentUpload(_ input: StartAttachmentUploadInput) async throws -> StartAttachmentUploadOutput {
        lastStartAttachmentUploadInput = input
        return try resolve(startAttachmentUploadResult)
    }

    func completeAttachmentUpload(_ input: CompleteAttachmentUploadInput) async throws -> CompleteAttachmentUploadOutput {
        lastCompleteAttachmentUploadInput = input
        return try resolve(completeAttachmnetUploadResult)
    }

    func getAttachment(_ input: GetAttachmentInput) async throws -> GetAttachmentOutput {
        lastGetAttachmentInput = input
        return try resolve(getAttachmentResult)
    }

    func describeView(_ input: DescribeViewInput) async throws -> DescribeViewOutput {
        lastDescribeViewInput = input
        return try resolve(describeViewResult)
    }

    // Throws when a test exercises an operation it did not stub.
    private func resolve<Output>(_ result: Result<Output, Error>?) throws -> Output {
        guard let result = result else {
            throw MockError.unexpected
        }
        return try result.get()
    }

    enum MockError: Error {
        case unexpected
    }
}
