// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import AWSConnectParticipant

protocol AWSConnectParticipantProtocol {
    func createParticipantConnection(_ request: AWSConnectParticipantCreateParticipantConnectionRequest?) -> AWSTask<AWSConnectParticipantCreateParticipantConnectionResponse>
    func disconnectParticipant(_ request: AWSConnectParticipantDisconnectParticipantRequest?) -> AWSTask<AnyObject>
    func sendMessage(_ request: AWSConnectParticipantSendMessageRequest?) -> AWSTask<AnyObject>
    func sendEvent(_ request: AWSConnectParticipantSendEventRequest?) -> AWSTask<AnyObject>
    func getTranscript(_ request: AWSConnectParticipantGetTranscriptRequest?) -> AWSTask<AWSConnectParticipantGetTranscriptResponse>
    func startAttachmentUpload(_ request: AWSConnectParticipantStartAttachmentUploadRequest?) -> AWSTask<AWSConnectParticipantStartAttachmentUploadResponse>
    func completeAttachmentUpload(_ request: AWSConnectParticipantCompleteAttachmentUploadRequest?) -> AWSTask<AWSConnectParticipantCompleteAttachmentUploadResponse>
    func getAttachment(_ request: AWSConnectParticipantGetAttachmentRequest?) -> AWSTask<AWSConnectParticipantGetAttachmentResponse>
}

class AWSConnectParticipantAdapter: AWSConnectParticipantProtocol {
    private let participant: AWSConnectParticipant

    init(participant: AWSConnectParticipant) {
        self.participant = participant
    }

    func createParticipantConnection(_ request: AWSConnectParticipantCreateParticipantConnectionRequest?) -> AWSTask<AWSConnectParticipantCreateParticipantConnectionResponse> {
        guard let request = request else {
            return AWSTask(error: NSError(domain: "AWSConnectParticipantAdapter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid request"]))
        }
        return participant.createParticipantConnection(request)
    }

    func disconnectParticipant(_ request: AWSConnectParticipantDisconnectParticipantRequest?) -> AWSTask<AnyObject> {
        guard let request = request else {
            return AWSTask(error: NSError(domain: "AWSConnectParticipantAdapter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid request"]))
        }
        return participant.disconnectParticipant(request).continueWith { task -> AWSTask<AnyObject> in
            if let error = task.error {
                return AWSTask(error: error)
            }
            return AWSTask(result: nil as AnyObject?)
        }
    }

    func sendMessage(_ request: AWSConnectParticipantSendMessageRequest?) -> AWSTask<AnyObject> {
        guard let request = request else {
            return AWSTask(error: NSError(domain: "AWSConnectParticipantAdapter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid request"]))
        }
        return participant.sendMessage(request).continueWith { task -> AWSTask<AnyObject> in
            if let error = task.error {
                return AWSTask(error: error)
            }
            return AWSTask(result: nil as AnyObject?)
        }
    }

    func sendEvent(_ request: AWSConnectParticipantSendEventRequest?) -> AWSTask<AnyObject> {
        guard let request = request else {
            return AWSTask(error: NSError(domain: "AWSConnectParticipantAdapter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid request"]))
        }
        return participant.sendEvent(request).continueWith { task -> AWSTask<AnyObject> in
            if let error = task.error {
                return AWSTask(error: error)
            }
            return AWSTask(result: nil as AnyObject?)
        }
    }

    func getTranscript(_ request: AWSConnectParticipantGetTranscriptRequest?) -> AWSTask<AWSConnectParticipantGetTranscriptResponse> {
        guard let request = request else {
            return AWSTask(error: NSError(domain: "AWSConnectParticipantAdapter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid request"]))
        }
        return participant.getTranscript(request)
    }

    func startAttachmentUpload(_ request: AWSConnectParticipantStartAttachmentUploadRequest?) -> AWSTask<AWSConnectParticipantStartAttachmentUploadResponse> {
        guard let request = request else {
            return AWSTask(error: NSError(domain: "AWSConnectParticipantAdapter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid request"]))
        }
        return participant.startAttachmentUpload(request)
    }
    
    func completeAttachmentUpload(_ request: AWSConnectParticipantCompleteAttachmentUploadRequest?) -> AWSTask<AWSConnectParticipantCompleteAttachmentUploadResponse> {
        guard let request = request else {
            return AWSTask(error: NSError(domain: "AWSConnectParticipantAdapter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid request"]))
        }
        return participant.completeAttachmentUpload(request)
    }
    
    func getAttachment(_ request: AWSConnectParticipantGetAttachmentRequest?) -> AWSTask<AWSConnectParticipantGetAttachmentResponse> {
        guard let request = request else {
            return AWSTask(error: NSError(domain: "AWSConnectParticipantAdapter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid request"]))
        }
        return participant.getAttachment(request)
    }
}
