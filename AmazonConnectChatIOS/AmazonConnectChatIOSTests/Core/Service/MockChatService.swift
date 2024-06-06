// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import Combine
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockChatService: ChatServiceProtocol {
    var createChatSessionResult: Result<Void, Error>?
    var disconnectChatSessionResult: Result<Void, Error>?
    var sendMessageResult: Result<Void, Error>?
    var sendEventResult: Result<Void, Error>?
    var sendAttachmentResult: Result<Void, Error>?
    var downloadAttachmentResult: Result<URL, Error>?
    var getTranscriptResult: Result<TranscriptResponse, Error>?
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptItemPublisher = PassthroughSubject<TranscriptItem, Never>()
    var transcriptListPublisher = CurrentValueSubject<[TranscriptItem], Never>([])
    var websocketManager: WebsocketManagerProtocol?

    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
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

    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void) {
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

    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void) {
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


    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void) {
        if let result = sendEventResult {
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
    
    func sendAttachment(file: URL, completion: @escaping (Bool, (any Error)?) -> Void) {
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
    
    func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
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

    func subscribeToEvents(handleEvent: @escaping (ChatEvent) -> Void) -> AnyCancellable {
        return eventPublisher.sink(receiveValue: handleEvent)
    }

    func subscribeToTranscriptItem(handleTranscriptItem: @escaping (TranscriptItem) -> Void) -> AnyCancellable {
        return transcriptItemPublisher.sink(receiveValue: handleTranscriptItem)
    }

    func subscribeToTranscriptList(handleTranscriptList: @escaping ([TranscriptItem]) -> Void) -> AnyCancellable {
        return transcriptListPublisher.sink(receiveValue: handleTranscriptList)
    }

    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<TranscriptResponse, Error>) -> Void) {
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

