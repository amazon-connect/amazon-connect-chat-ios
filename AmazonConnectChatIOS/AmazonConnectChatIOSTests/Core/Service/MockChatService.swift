import Foundation
import Combine
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockChatService: ChatServiceProtocol {
    var createChatSessionResult: (Bool, Error?)?
    var disconnectChatSessionResult: (Bool, Error?)?
    var sendMessageResult: (Bool, Error?)?
    var sendEventResult: (Bool, Error?)?
    var getTranscriptResult: Result<[AWSConnectParticipantItem], Error>?
    var eventPublisher = PassthroughSubject<ChatEvent, Never>()
    var transcriptItemPublisher = PassthroughSubject<TranscriptItem, Never>()
    var transcriptListPublisher = CurrentValueSubject<[TranscriptItem], Never>([])

    func createChatSession(chatDetails: ChatDetails, completion: @escaping (Bool, Error?) -> Void) {
        if let result = createChatSessionResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(result.0, result.1)
                if result.0 {
                    self.eventPublisher.send(.connectionEstablished)
                }
            }
        }
    }

    func disconnectChatSession(completion: @escaping (Bool, Error?) -> Void) {
        if let result = disconnectChatSessionResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(result.0, result.1)
                if result.0 {
                    self.eventPublisher.send(.chatEnded)
                }
            }
        }
    }

    func sendMessage(contentType: ContentType, message: String, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let result = self.sendMessageResult {
                completion(result.0, result.1)
            }
        }
    }


    func sendEvent(event: ContentType, content: String?, completion: @escaping (Bool, Error?) -> Void) {
        if let result = sendEventResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(result.0, result.1)
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

    func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<[AWSConnectParticipantItem], Error>) -> Void) {
        if let result = getTranscriptResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(result)
            }
        }
    }
}

