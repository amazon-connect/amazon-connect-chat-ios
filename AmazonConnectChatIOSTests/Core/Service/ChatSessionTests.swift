// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class ChatSessionTests: XCTestCase {
    var chatSession: ChatSession!
    var mockChatService: MockChatService!
    var testFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sample.txt")
    
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
        
        let expectation = XCTestExpectation(description: "ConnectionTest")
        
        chatSession.onConnectionEstablished = {
            connectionEstablished = true
            if case .success = expectedResult {
                expectation.fulfill()
            }
        }
        
        mockChatService.createChatSessionResult = expectedResult
        chatSession.connect(chatDetails: chatDetails) { result in
            switch result {
            case .success:
                if !connectionEstablished {
                    expectation.fulfill()
                }
            case .failure(let error):
                receivedError = error
                expectation.fulfill()
            }
        }
        
        let waiterResult = XCTWaiter().wait(for: [expectation], timeout: 1)
        XCTAssertEqual(waiterResult, .completed, "Expectation should be fulfilled")
        
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
    func performDisconnectTest(expectedResult: Result<Void, Error>, onChatEnded: (() -> Void)? = nil) {
        var chatEnded = false
        var receivedError: Error?
        
        let expectation = XCTestExpectation(description: "DisconnectTest")
        
        chatSession.onChatEnded = {
            chatEnded = true
            if case .success = expectedResult {
                expectation.fulfill()
            }
        }
        
        mockChatService.disconnectChatSessionResult = expectedResult
        chatSession.disconnect { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                receivedError = error
                expectation.fulfill()
            }
        }
        
        let waiterResult = XCTWaiter().wait(for: [expectation], timeout: 1)
        XCTAssertEqual(waiterResult, .completed, "Expectation should be fulfilled")
        
        if let onChatEnded = onChatEnded {
            onChatEnded()
        }
        
        switch expectedResult {
        case .success:
            XCTAssertTrue(chatEnded, "Chat should end")
        case .failure(let expectedError):
            XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, "Should receive the expected error")
        }
    }
    
    // Test the successful disconnection scenario
    func testDisconnect_Success() {
        performDisconnectTest(expectedResult: .success(()))
    }
    
    // Test the unsuccessful disconnection scenario
    func testDisconnect_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performDisconnectTest(expectedResult: .failure(expectedError))
    }
    
    // Helper method for send message tests
    func performSendMessageTest(contentType: ContentType, message: String, expectedResult: Result<Void, Error>) {
        var receivedError: Error?
        
        let expectation = XCTestExpectation(description: "SendMessageTest")
        
        mockChatService.sendMessageResult = expectedResult
        chatSession.sendMessage(contentType: contentType, message: message) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                receivedError = error
                expectation.fulfill()
            }
        }
        
        let waiterResult = XCTWaiter().wait(for: [expectation], timeout: 1)
        XCTAssertEqual(waiterResult, .completed, "Expectation should be fulfilled")
        
        switch expectedResult {
        case .success:
            XCTAssertNil(receivedError, "Error should be nil on successful message send")
        case .failure(let expectedError):
            XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, "Should receive the expected error")
        }
    }
    
    
    // Test the successful sendMessage scenario
    func testSendMessage_Success() {
        performSendMessageTest(contentType: .plainText, message: "Test Message", expectedResult: .success(()))
    }
    
    // Test the unsuccessful sendMessage scenario
    func testSendMessage_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performSendMessageTest(contentType: .plainText, message: "Test Message", expectedResult: .failure(expectedError))
    }
    
    // Helper method for resendFailedMessage tests
    func performResendFailedMessageTest(messageId: String, expectedResult: Result<Void, Error>) {
        var receivedError: Error?
        
        let expectation = XCTestExpectation(description: "SendMessageTest")
        
        mockChatService.resendFailedMessageResult = expectedResult
        chatSession.resendFailedMessage(messageId: messageId) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                receivedError = error
                expectation.fulfill()
            }
        }
        
        let waiterResult = XCTWaiter().wait(for: [expectation], timeout: 1)
        XCTAssertEqual(waiterResult, .completed, "Expectation should be fulfilled")
        
        switch expectedResult {
        case .success:
            XCTAssertNil(receivedError, "Error should be nil on successful message send")
        case .failure(let expectedError):
            XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, "Should receive the expected error")
        }
    }
    
    // Test the successful testResendFailedMessage scenario
    func testResendFailedMessage_Success() {
        performResendFailedMessageTest(messageId: "TestMessageId", expectedResult: .success(()))
    }
    
    // Test the unsuccessful testResendFailedMessage scenario
    func testResendFailedMessage_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performResendFailedMessageTest(messageId: "TestMessageId", expectedResult: .failure(expectedError))
    }
    
    // Helper method for send event tests
    func performSendEventTest(eventType: ContentType, content: String, expectedResult: (Bool, Error?)?) {
        var receivedError: Error?
        
        let expectation = XCTestExpectation(description: "SendEventTest")
        
        mockChatService.sendEventResult = expectedResult
        chatSession.sendEvent(event: eventType, content: content) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                receivedError = error
                expectation.fulfill()
            }
        }
        
        let waiterResult = XCTWaiter().wait(for: [expectation], timeout: 1)
        XCTAssertEqual(waiterResult, .completed, "Expectation should be fulfilled")

        if let result = expectedResult {
            let (success, error) = result
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                if success {
                    XCTAssertNil(receivedError, "Error should be nil on successful event send")
                } else if error != nil {
                    XCTAssertEqual(receivedError as NSError?, error as NSError?, "Should receive the expected error")
                }
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
        performSendEventTest(eventType: .typing, content: "Test Event", expectedResult: (false, expectedError))
    }
    
    // Helper method for get transcript tests
    func performGetTranscriptTest(
        scanDirection: AWSConnectParticipantScanDirection?,
        sortOrder: AWSConnectParticipantSortKey?,
        maxResults: NSNumber?,
        nextToken: String?,
        startPosition: String?,
        expectedResult: Result<TranscriptResponse, Error>
    ) {
        var receivedError: Error?
        var receivedTranscript: TranscriptResponse?
        let expectation = self.expectation(description: "GetTranscriptTest")
        
        mockChatService.getTranscriptResult = expectedResult
        chatSession.getTranscript(scanDirection: scanDirection, sortOrder: sortOrder, maxResults: maxResults, nextToken: nextToken, startPosition: startPosition) { result in
            switch result {
            case .success(let transcript):
                receivedTranscript = transcript
                expectation.fulfill()
            case .failure(let error):
                receivedError = error
                expectation.fulfill()
            }
        }
        
        let waiterResult = XCTWaiter().wait(for: [expectation], timeout: 1)
        XCTAssertEqual(waiterResult, .completed, "Expectation should be fulfilled")
        
        switch expectedResult {
        case .success(let expectedTranscript):
            XCTAssertEqual(receivedTranscript, expectedTranscript, "Should receive the expected transcript")
        case .failure(let expectedError):
            XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, "Should receive the expected error")
        }
    }
    
    // Test the successful getTranscript scenario
    func testGetTranscript_Success() {
        let items = [TranscriptItem(timeStamp: "timestamp", contentType: ContentType.plainText.rawValue, id: "12345", serializedContent: ["content": "testContent"])] // Mock TranscriptItem data
        let transcriptResponse = TranscriptResponse(initialContactId: "testContactId", nextToken: "testNextToken", transcript: items)
        performGetTranscriptTest(scanDirection: .backward, sortOrder: .ascending, maxResults: 15, nextToken: nil, startPosition: nil, expectedResult: .success(transcriptResponse))
    }
    
    // Test the unsuccessful getTranscript scenario
    func testGetTranscript_Failure() {
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        performGetTranscriptTest(scanDirection: .backward, sortOrder: .ascending, maxResults: 15, nextToken: nil, startPosition: nil, expectedResult: .failure(expectedError))
    }
    
    func testSendAttachment_Success() {
        let expectation = self.expectation(description: "SendAttachment succeeds")

        mockChatService.sendAttachmentResult = .success(())
        chatSession.sendAttachment(file: testFileUrl) { result in
            switch result {
            case .success():
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
            
    func testSendAttachment_Failure() {
        let expectation = self.expectation(description: "SendAttachment fails")
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        mockChatService.sendAttachmentResult = .failure(expectedError)
        chatSession.sendAttachment(file: testFileUrl) { result in
            switch result {
            case .success():
                XCTFail("Expected failure, got unexpected success")
            case .failure(let error):
                XCTAssertEqual(error as NSError, expectedError)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDownloadAttachment_Success() {
        let expectation = self.expectation(description: "DownloadAttachment succeeds")

        mockChatService.downloadAttachmentResult = .success(testFileUrl)
        chatSession.downloadAttachment(attachmentId: "12345", filename: "sample.txt") { result in
            switch result {
            case .success(let url):
                XCTAssertEqual(url, self.testFileUrl)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testDownloadAttachment_Failure() {
        let expectation = self.expectation(description: "DownloadAttachment fails")
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        mockChatService.downloadAttachmentResult = .failure(expectedError)
        chatSession.downloadAttachment(attachmentId: "12345", filename: "sample.txt") { result in
            switch result {
            case .success(let url):
                XCTFail("Expected failure, got unexpected success: \(String(describing: url))")
            case .failure(let error):
                XCTAssertEqual(error as NSError, expectedError)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testGetAttachmentDownloadUrl_Success() {
        let expectation = self.expectation(description: "GetAttachmentDownloadUrl succeeds")

        mockChatService.getAttachmentDownloadUrlResult = .success(testFileUrl)
        chatSession.getAttachmentDownloadUrl(attachmentId: "12345") { result in
            switch result {
            case .success(let url):
                XCTAssertEqual(url, self.testFileUrl)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testGetAttachmentDownloadUrl_Failure() {
        let expectation = self.expectation(description: "GetAttachmentDownloadUrl fails")
        let expectedError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        mockChatService.getAttachmentDownloadUrlResult = .failure(expectedError)
        chatSession.getAttachmentDownloadUrl(attachmentId: "12345") { result in
            switch result {
            case .success(let url):
                XCTFail("Expected failure, got unexpected success: \(String(describing: url))")
            case .failure(let error):
                XCTAssertEqual(error as NSError, expectedError)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
