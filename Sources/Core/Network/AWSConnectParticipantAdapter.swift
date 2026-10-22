// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant

/// Injection seam for the generated `ConnectParticipantClient`, which is a `final class` with no
/// generated protocol and so cannot be mocked directly.
protocol AWSConnectParticipantProtocol {
    func createParticipantConnection(_ input: CreateParticipantConnectionInput) async throws -> CreateParticipantConnectionOutput
    func disconnectParticipant(_ input: DisconnectParticipantInput) async throws -> DisconnectParticipantOutput
    func sendMessage(_ input: SendMessageInput) async throws -> SendMessageOutput
    func sendEvent(_ input: SendEventInput) async throws -> SendEventOutput
    func getTranscript(_ input: GetTranscriptInput) async throws -> GetTranscriptOutput
    func startAttachmentUpload(_ input: StartAttachmentUploadInput) async throws -> StartAttachmentUploadOutput
    func completeAttachmentUpload(_ input: CompleteAttachmentUploadInput) async throws -> CompleteAttachmentUploadOutput
    func getAttachment(_ input: GetAttachmentInput) async throws -> GetAttachmentOutput
    func describeView(_ input: DescribeViewInput) async throws -> DescribeViewOutput
}

final class AWSConnectParticipantAdapter: AWSConnectParticipantProtocol {
    private let client: ConnectParticipantClient

    init(client: ConnectParticipantClient) {
        self.client = client
    }

    func createParticipantConnection(_ input: CreateParticipantConnectionInput) async throws -> CreateParticipantConnectionOutput {
        try await client.createParticipantConnection(input: input)
    }

    func disconnectParticipant(_ input: DisconnectParticipantInput) async throws -> DisconnectParticipantOutput {
        try await client.disconnectParticipant(input: input)
    }

    func sendMessage(_ input: SendMessageInput) async throws -> SendMessageOutput {
        try await client.sendMessage(input: input)
    }

    func sendEvent(_ input: SendEventInput) async throws -> SendEventOutput {
        try await client.sendEvent(input: input)
    }

    func getTranscript(_ input: GetTranscriptInput) async throws -> GetTranscriptOutput {
        try await client.getTranscript(input: input)
    }

    func startAttachmentUpload(_ input: StartAttachmentUploadInput) async throws -> StartAttachmentUploadOutput {
        try await client.startAttachmentUpload(input: input)
    }

    func completeAttachmentUpload(_ input: CompleteAttachmentUploadInput) async throws -> CompleteAttachmentUploadOutput {
        try await client.completeAttachmentUpload(input: input)
    }

    func getAttachment(_ input: GetAttachmentInput) async throws -> GetAttachmentOutput {
        try await client.getAttachment(input: input)
    }

    func describeView(_ input: DescribeViewInput) async throws -> DescribeViewOutput {
        try await client.describeView(input: input)
    }
}
