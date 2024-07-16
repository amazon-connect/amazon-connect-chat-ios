// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MessageReceiptsManagerTests: XCTestCase {
    var messageReceiptsManager: MockMessageReceiptsManager?
    
    override func setUp() {
        messageReceiptsManager = MockMessageReceiptsManager()
        messageReceiptsManager?.throttleTime = 0.1
        messageReceiptsManager?.deliveredThrottleTime = 0.1
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func waitFor(seconds: TimeInterval) {
        let expectation = self.expectation(description: "Waiting")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: seconds + 1, handler: nil)
    }
    
    func testThrottleAndSendMessageReceipt_Succeeds() {
        let expectation = self.expectation(description: "throttleAndSendMessageReceipt succeeds")
        messageReceiptsManager?.mockThrottleAndSendMessageReceipt = false
        let mockPendingMessageReceipts = PendingMessageReceipts(readReceiptMessageId: "12345", deliveredReceiptMessageId: "67890")
        messageReceiptsManager?.pendingMessageReceipts = mockPendingMessageReceipts
        
        messageReceiptsManager?.throttleAndSendMessageReceipt(event: .messageRead, messageId: "12345") { result in
            switch result {
            case .success(let pendingMessageReceipts):
                XCTAssertEqual(pendingMessageReceipts.readReceiptMessageId, mockPendingMessageReceipts.readReceiptMessageId)
                XCTAssertEqual(pendingMessageReceipts.deliveredReceiptMessageId, mockPendingMessageReceipts.deliveredReceiptMessageId)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testHandleMessageReceipt_ReadSucceeds() {
        
        // Check that handling a read receipt updates the set and pendingMessageReceipts object
        messageReceiptsManager?.handleMessageReceipt(event: .messageRead, messageId: "12345")
        XCTAssertEqual(messageReceiptsManager?.readReceiptSet.count, 1)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.readReceiptMessageId, "12345")
        
        // Check that sending a read receipt for the same message doesn't change the set
        messageReceiptsManager?.handleMessageReceipt(event: .messageRead, messageId: "12345")
        XCTAssertEqual(messageReceiptsManager?.readReceiptSet.count, 1)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.readReceiptMessageId, "12345")
        
        // Check that sending a read receipt for a different message increases set size and updates pendingMessageReceipts object
        messageReceiptsManager?.handleMessageReceipt(event: .messageRead, messageId: "67890")
        XCTAssertEqual(messageReceiptsManager?.readReceiptSet.count, 2)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.readReceiptMessageId, "67890")
    }
    
    func testHandleMessageReceipt_DeliveredSucceeds() {
        // Check that sending a delivered receipt increases set size and is initialy throttled before updating pendingMessageReceipts object
        messageReceiptsManager?.handleMessageReceipt(event: .messageDelivered, messageId: "12345")
        XCTAssertEqual(messageReceiptsManager?.deliveredReceiptSet.count, 1)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.deliveredReceiptMessageId, nil)
        waitFor(seconds: 0.2)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.deliveredReceiptMessageId, "12345")
        
        // Check that sending a duplicate delivered receipt does not increase set.
        messageReceiptsManager?.handleMessageReceipt(event: .messageDelivered, messageId: "12345")
        XCTAssertEqual(messageReceiptsManager?.deliveredReceiptSet.count, 1)
        
        // Check that sending a delivered receipt for a new message increases set size and updates pendingMessageReceipts object
        messageReceiptsManager?.handleMessageReceipt(event: .messageDelivered, messageId: "67890")
        XCTAssertEqual(messageReceiptsManager?.deliveredReceiptSet.count, 2)
        waitFor(seconds: 0.2)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.deliveredReceiptMessageId, "67890")
    }
    
    func testHandleMessageReceipt_ReadDeliveredSucceeds() {
        // Send message receipt for a given message
        messageReceiptsManager?.handleMessageReceipt(event: .messageRead, messageId: "12345")
        XCTAssertEqual(messageReceiptsManager?.readReceiptSet.count, 1)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.readReceiptMessageId, "12345")
        
        // Send delivered receipt for same message and expect pendingMessageReceipts.deliveredReceiptMessageId to not be updated
        messageReceiptsManager?.handleMessageReceipt(event: .messageDelivered, messageId: "12345")
        XCTAssertEqual(messageReceiptsManager?.deliveredReceiptSet.count, 0)
        waitFor(seconds: 0.2)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.deliveredReceiptMessageId, nil)
        
        // Send delivered receipt immediately followed by read receipt and expect pendingMessageReceipts.deliveredReceiptMessageId to be unchanged.
        messageReceiptsManager?.handleMessageReceipt(event: .messageDelivered, messageId: "67890")
        messageReceiptsManager?.handleMessageReceipt(event: .messageRead, messageId: "67890")
        XCTAssertEqual(messageReceiptsManager?.deliveredReceiptSet.count, 1)
        waitFor(seconds: 0.2)
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.readReceiptMessageId, "67890")
        XCTAssertEqual(messageReceiptsManager?.pendingMessageReceipts.deliveredReceiptMessageId, nil)
    }
}
