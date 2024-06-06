// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import Combine
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockChatService: ChatService {
    var mockCreateChatSession = true
    var mockDisconnectChatSession = true
    var mockSendMessage = true
    var mockSendEvent = true
    var mockSendMessageReceipt = true
    var mockSendPendingMessageReceipts = true
    var mockSendAttachment = true
    var mockStartAttachmentUpload = true
    var mockDownloadAttachment = true
    var mockDownloadFile = true
    var mockGetAttachmentDownloadUrl = true
    var mockCompleteAttachmentUpload = true
    var mockGetTranscript = true
    
    var numCreateChatSessionCalled = 0
    var numDisconnectChatSessionCalled = 0
    var numSendMessageCalled = 0
    var numSendEventCalled = 0
    var numSendMessageReceiptCalled = 0
    var numSendPendingMessageReceiptsCalled = 0
    var numSendAttachmentCalled = 0
    var numStartAttachmentUploadCalled = 0
    var numDownloadAttachmentCalled = 0
    var numDownloadFileCalled = 0
    var numGetAttachmentDownloadUrlCalled = 0
    var numCompleteAttachmentUploadCalled = 0
    var numGetTranscriptCalled = 0
    
    var createChatSessionResult: Result<Void, Error>?
    var disconnectChatSessionResult: Result<Void, Error>?
    var sendMessageResult: Result<Void, Error>?
    var sendEventResult: (Bool, Error?)?
    var sendMessageReceiptResult: Result<Void, Error>?
    var sendPendingMessageReceiptsResult: Result<AmazonConnectChatIOS.MessageReceiptType, Error>?
    var sendAttachmentResult: Result<Void, Error>?
    var startAttachmentUploadResult: Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>?
    var downloadAttachmentResult: Result<URL, Error>?
    var downloadFileResult: (URL?, Error?)?
    var getAttachmentDownloadUrlResult: Result<URL, Error>?
    var completeAttachmentUploadResult: (Bool, Error?)?
    var getTranscriptResult: Result<TranscriptResponse, Error>?

    var websocketManager: WebsocketManagerProtocol?

    override func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
        
        numCreateChatSessionCalled += 1
        if !mockCreateChatSession {
            super.createChatSession(chatDetails: chatDetails, completion: completion)
            return
        }
        
        if let result = createChatSessionResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success:
                    completion(true, nil)
                    self.eventPublisher.send(.connectionEstablished)
                case .failure(let error):
                    completion(false, error)
                }
            }
        }
    }

    override func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void) {
        
        numDisconnectChatSessionCalled += 1
        if !mockDisconnectChatSession {
            super.disconnectChatSession(completion: completion)
            return
        }
        
        if let result = disconnectChatSessionResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success:
                    completion(true, nil)
                    self.eventPublisher.send(.chatEnded)
                case .failure(let error):
                    completion(false, error)
                }
            }
        }
    }

    override func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void) {
        
        numSendMessageCalled += 1
        if !mockSendMessage {
            super.sendMessage(contentType: contentType, message: message, completion: completion)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let result = self.sendMessageResult {
                switch result {
                case .success:
                    completion(true, nil)
                case .failure(let error):
                    completion(false, error)
                }
            }
        }
    }


    override func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void) {
        
        numSendEventCalled += 1
        if !mockSendEvent {
            super.sendEvent(event: event, content: content, completion: completion)
            return
        }
        
        if let result = sendEventResult {
            let (success, error) = result
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    override func sendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        numSendMessageReceiptCalled += 1
        if !mockSendMessageReceipt {
            super.sendMessageReceipt(event: event, messageId: messageId, completion: completion)
            return
        }
        
        if let result = sendMessageReceiptResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    override func sendPendingMessageReceipts(pendingMessageReceipts: AmazonConnectChatIOS.PendingMessageReceipts, completion: @escaping (Result<AmazonConnectChatIOS.MessageReceiptType, any Error>) -> Void) {
        
        numSendPendingMessageReceiptsCalled += 1
        if !mockSendPendingMessageReceipts {
            super.sendPendingMessageReceipts(pendingMessageReceipts: pendingMessageReceipts, completion: completion)
            return
        }
        
        if let result = sendPendingMessageReceiptsResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success:
                    completion(.success(.messageRead))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    override func sendAttachment(file: URL, completion: @escaping (Bool, (any Error)?) -> Void) {
        numSendAttachmentCalled += 1
        
        if !mockSendAttachment {
            super.sendAttachment(file: file, completion: completion)
            return
        }
    
        if let result = sendAttachmentResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success:
                    completion(true, nil)
                case .failure(let error):
                    completion(false, error)
                }
            }
        }
    }
    
    override func startAttachmentUpload(contentType: String, attachmentName: String, attachmentSizeInBytes: Int, completion: @escaping (Result<AWSConnectParticipantStartAttachmentUploadResponse, Error>) -> Void) {

        numStartAttachmentUploadCalled += 1
        if !mockStartAttachmentUpload {
            super.startAttachmentUpload(contentType: contentType, attachmentName: attachmentName, attachmentSizeInBytes: attachmentSizeInBytes, completion: completion)
        }
        
        if let result = startAttachmentUploadResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    override func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        numDownloadAttachmentCalled += 1
        if !mockDownloadAttachment {
            super.downloadAttachment(attachmentId: attachmentId, filename: filename, completion: completion)
            return
        }
        
        if let result = downloadAttachmentResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success(let url):
                    completion(.success(url))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    override func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        numGetAttachmentDownloadUrlCalled += 1
        if !mockGetAttachmentDownloadUrl {
            super.getAttachmentDownloadUrl(attachmentId: attachmentId, completion: completion)
            return
        }
        
        if let result = getAttachmentDownloadUrlResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success(let url):
                    completion(.success(url))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    override func completeAttachmentUpload(attachmentIds: [String], completion: @escaping (Bool, Error?) -> Void) {
        
        numCompleteAttachmentUploadCalled += 1
        if !mockCompleteAttachmentUpload {
            super.completeAttachmentUpload(attachmentIds: attachmentIds, completion: completion)
            return
        }
        
        if let result = completeAttachmentUploadResult {
            let (success, error) = result
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    override func downloadFile(url: URL, filename: String, completion: @escaping (URL?, (any Error)?) -> Void) {
        numDownloadFileCalled += 1
        if !mockDownloadFile {
            super.downloadFile(url: url, filename: filename, completion: completion)
            return
        }
        
        if let result = downloadFileResult {
            let (url, error) = result
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                if url != nil {
                    completion(url, nil)
                } else {
                    completion(nil, error)
                }
            }
        }
    }

    override func subscribeToEvents(handleEvent: @escaping (ChatEvent) -> Void) -> AnyCancellable {
        return eventPublisher.sink(receiveValue: handleEvent)
    }

    override func subscribeToTranscriptItem(handleTranscriptItem: @escaping (TranscriptItem) -> Void) -> AnyCancellable {
        return transcriptItemPublisher.sink(receiveValue: handleTranscriptItem)
    }

    override func subscribeToTranscriptList(handleTranscriptList: @escaping ([TranscriptItem]) -> Void) -> AnyCancellable {
        return transcriptListPublisher.sink(receiveValue: handleTranscriptList)
    }

    override func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<TranscriptResponse, Error>) -> Void) {

        numGetTranscriptCalled += 1
        if !mockGetTranscript {
            super.getTranscript(scanDirection: scanDirection, sortOrder: sortOrder, maxResults: maxResults, nextToken: nextToken, startPosition: startPosition, completion: completion)
            return
        }
        
            if let result = getTranscriptResult {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    switch result {
                    case .success(let response):
                        completion(.success(response))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
}

