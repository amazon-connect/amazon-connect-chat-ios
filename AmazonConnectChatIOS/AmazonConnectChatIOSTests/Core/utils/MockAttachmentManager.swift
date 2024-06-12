// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import XCTest
import UniformTypeIdentifiers
import AWSConnectParticipant

@testable import AmazonConnectChatIOS

class MockAttachmentManager: ChatService {
    var startAttachmentUploadCalled = false
    var completeAttachmentUploadCalled = false
    var downloadFileCalled = false
    
    var mockStartAttachmentUpload = true
    var mockCompleteAttachmentUpload = true
    var mockDownloadFile = true

    override func startAttachmentUpload(contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>) -> Void) {
        if mockStartAttachmentUpload {
            startAttachmentUploadCalled = true
            let mockResponse = AWSConnectParticipantStartAttachmentUploadResponse()
            mockResponse!.attachmentId = "mockAttachmentId"
            completion(.success(mockResponse!))
        } else {
            super.startAttachmentUpload(contentType: contentType, attachmentName: attachmentName, attachmentSizeInBytes: attachmentSizeInBytes, completion: completion)
        }
    }

    override func completeAttachmentUpload(attachmentIds: [String], completion: @escaping (Bool, Error?) -> Void) {
        if mockCompleteAttachmentUpload {
            completeAttachmentUploadCalled = true
            completion(true, nil)
        } else {
            super.completeAttachmentUpload(attachmentIds: attachmentIds, completion: completion)
        }
    }
    
    override func downloadFile(url: URL, filename: String, completion: @escaping (URL?, Error?) -> Void) {
        if mockDownloadFile {
            completeAttachmentUploadCalled = true
            completion(url, nil)
        } else {
            super.downloadFile(url: url, filename: filename, completion: completion)
        }
    }
}
