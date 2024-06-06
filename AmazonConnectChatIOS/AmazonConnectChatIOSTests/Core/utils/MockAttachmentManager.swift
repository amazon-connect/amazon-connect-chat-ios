//
//  MockAttachmentManager.swift
//  AmazonConnectChatIOSTests
//
//  Created by Liao, Michael on 6/8/24.
//

import XCTest
import UniformTypeIdentifiers
import AWSConnectParticipant

@testable import AmazonConnectChatIOS

class MockAttachmentManager: ChatService {
    var startAttachmentUploadCalled = false
    var uploadAttachmentCalled = false
    var completeAttachmentUploadCalled = false
    var downloadFileCalled = false
    
    var mockStartAttachmentUpload = true
    var mockUploadAttachment = true
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

    override func uploadAttachment(file: URL, response: AWSConnectParticipantStartAttachmentUploadResponse, completion: @escaping (Bool, Error?) -> Void) {
        if mockUploadAttachment {
            uploadAttachmentCalled = true
            completion(true, nil)
        } else {
            super.uploadAttachment(file: file, response: response, completion: completion)
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
