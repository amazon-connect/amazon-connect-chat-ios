//
//  MockAWSClient.swift
//  AmazonConnectChatIOSTests
//
//  Created by Mittal, Rajat on 5/16/24.
//

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAWSClient: AWSClientProtocol {
    var createParticipantConnectionResult: Result<ConnectionDetails, Error>?
    var disconnectParticipantConnectionResult: Result<Bool, Error>?
    var sendMessageResult: Result<Bool, Error>?
    var sendEventResult: Result<Bool, Error>?
    var getTranscriptResult: Result<[AWSConnectParticipantItem], Error>?
    
    func createParticipantConnection(participantToken: String, completion: @escaping (Result<ConnectionDetails, Error>) -> Void) {
        if let result = createParticipantConnectionResult {
            completion(result)
        }
    }
    
    func disconnectParticipantConnection(connectionToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if let result = disconnectParticipantConnectionResult {
            completion(result)
        }
    }
    
    func sendMessage(connectionToken: String, contentType: ContentType, message: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if let result = sendMessageResult {
            completion(result)
        }
    }
    
    func sendEvent(connectionToken: String, contentType: ContentType, content: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if let result = sendEventResult {
            completion(result)
        }
    }
    
    func getTranscript(getTranscriptArgs: AWSConnectParticipantGetTranscriptRequest, completion: @escaping (Result<[AWSConnectParticipantItem], Error>) -> Void) {
        if let result = getTranscriptResult {
            completion(result)
        }
    }
}

