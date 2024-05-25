//
//  ChatSessionTests.swift
//  AmazonConnectChatIOSTests
//
//  Created by Mittal, Rajat on 5/16/24.
//

import XCTest
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class ChatSessionTests: XCTestCase {
    var chatSession: ChatSession!
    var mockChatService: MockChatService!
    
    override func setUp() {
        super.setUp()
        mockChatService = MockChatService()
        chatSession = ChatSession(chatService: mockChatService)
    }
    
    override func tearDown() {
        chatSession = nil
        mockChatService = nil
        super.tearDown()
    }
    
    // Helper method for connection tests
    func performConnectTest(chatDetails: ChatDetails, expectedResult: Result<Void, Error>, onConnectionEstablished: (() -> Void)? = nil) {
        var connectionEstablished = false
        var receivedError: Error?
        var expectationFulfilled = false // Flag to track if expectation is fulfilled
        let expectation = self.expectation(description: "ConnectionTest")
        
        chatSession.onConnectionEstablished = {
            connectionEstablished = true
            if case .success = expectedResult {
                if !expectationFulfilled {
                    expectation.fulfill()
                    expectationFulfilled = true
                }
            }
        }
        
        mockChatService.createChatSessionResult = expectedResult
        chatSession.connect(chatDetails: chatDetails) { result in
            switch result {
            case .success:
                if !connectionEstablished && !expectationFulfilled {
                    expectation.fulfill()
                    expectationFulfilled = true
                }
            case .failure(let error):
                receivedError = error
                if !expectationFulfilled {
                    expectation.fulfill()
                    expectationFulfilled = true
                }
            }
        }
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
            if let onConnectionEstablished = onConnectionEstablished {
                onConnectionEstablished()
            }
            switch expectedResult {
            case .success:
                XCTAssertTrue(connectionEstablished, "Connection should be established")
            case .failure(let expectedError):
                XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, "Should receive the expected error")
            }
        }
    }


    
    // Test the successful connection scenario
    func testConnect_Success() {
        let chatDetails = ChatDetails(contactId: "testContactId", participantId: "testParticipantId", participantToken: "testParticipantToken")
        performConnectTest(chatDetails: chatDetails, expectedResult: .success(()))
    }
    
    // Test the unsuccessful connection scenario
    func testConnect_Failure() {
        let chatDetails = ChatDetails(contactId: "testContactId", participantId: "testParticipantId", participantToken: "testParticipantToken")
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performConnectTest(chatDetails: chatDetails, expectedResult: .failure(expectedError))
    }
    
    // Helper method for disconnection tests
    func performDisconnectTest(expectedResult: (Bool, Error?), onChatEnded: (() -> Void)? = nil, expectedError: Error? = nil) {
        var chatEnded = false
        var receivedError: Error?
        let expectation = self.expectation(description: "DisconnectTest")
        
        chatSession.onChatEnded = {
            chatEnded = true
            expectation.fulfill()
        }
        
        mockChatService.disconnectChatSessionResult = expectedResult
        chatSession.disconnect { error in
            receivedError = error
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
            if let onChatEnded = onChatEnded {
                onChatEnded()
            }
            if let expectedError = expectedError {
                XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, "Should receive the expected error")
            } else {
                XCTAssertTrue(chatEnded, "Chat should end")
            }
        }
    }
    
    // Test the successful disconnection scenario
    func testDisconnect_Success() {
        performDisconnectTest(expectedResult: (true, nil))
    }
    
    // Test the unsuccessful disconnection scenario
    func testDisconnect_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performDisconnectTest(expectedResult: (false, expectedError), expectedError: expectedError)
    }
    
    // Helper method for send message tests
    func performSendMessageTest(contentType: ContentType, message: String, expectedResult: (Bool, Error?), expectedError: Error? = nil) {
        var receivedError: Error?
        let expectation = self.expectation(description: "SendMessageTest")
        
        mockChatService.sendMessageResult = expectedResult
        chatSession.sendMessage(contentType: contentType, message: message, onError: { error in
            receivedError = error
            expectation.fulfill()
        })
        
        if expectedError == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
            if let expectedError = expectedError {
                XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, "Should receive the expected error")
            } else {
                XCTAssertNil(receivedError, "Error should be nil on successful message send")
            }
        }
    }
    
    // Test the successful sendMessage scenario
    func testSendMessage_Success() {
        performSendMessageTest(contentType: .plainText, message: "Test Message", expectedResult: (true, nil))
    }
    
    // Test the unsuccessful sendMessage scenario
    func testSendMessage_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performSendMessageTest(contentType: .plainText, message: "Test Message", expectedResult: (false, expectedError), expectedError: expectedError)
    }
    
    
    // Helper method for send event tests
    func performSendEventTest(eventType: ContentType, content: String, expectedResult: (Bool, Error?), expectedError: Error? = nil) {
        var receivedError: Error?
        let expectation = self.expectation(description: "SendEventTest")
        
        mockChatService.sendEventResult = expectedResult
        chatSession.sendEvent(event: eventType, content: content, onError: { error in
            receivedError = error
            expectation.fulfill()
        })
        
        if expectedError == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
            if let expectedError = expectedError {
                XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, "Should receive the expected error")
            } else {
                XCTAssertNil(receivedError, "Error should be nil on successful event send")
            }
        }
    }
    
    // Test the successful sendEvent scenario
    func testSendEvent_Success() {
        performSendEventTest(eventType: .typing, content: "Test Event", expectedResult: (true, nil))
    }
    
    // Test the unsuccessful sendEvent scenario
    func testSendEvent_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performSendEventTest(eventType: .typing, content: "Test Event", expectedResult: (false, expectedError), expectedError: expectedError)
    }
    
    // Helper method for get transcript tests
    func performGetTranscriptTest(expectedResult: Result<[AWSConnectParticipantItem], Error>, expectedError: Error? = nil) {
        var receivedError: Error?
        let expectation = self.expectation(description: "GetTranscriptTest")
        
        mockChatService.getTranscriptResult = expectedResult
        chatSession.getTranscript()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
        }
    }
    
    // Test the successful getTranscript scenario
    func testGetTranscript_Success() {
        let items = [AWSConnectParticipantItem()!]
        performGetTranscriptTest(expectedResult: .success(items))
    }
    
    // Test the unsuccessful getTranscript scenario
    func testGetTranscript_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performGetTranscriptTest(expectedResult: .failure(expectedError), expectedError: expectedError)
    }

}
