// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import UniformTypeIdentifiers
import AWSConnectParticipant

@testable import AmazonConnectChatIOS

class MockMessageReceiptsManager: MessageReceiptsManager {
    var mockThrottleAndSendMessageReceipt = true
    
    var numThrottleAndSendMessageReceiptCalled = 0
    var numInvalidateTimerCalled = 0
    var numHandleMessageReceiptCalled = 0
   
    var throttleAndSendMessageReceiptResult: Result<AmazonConnectChatIOS.PendingMessageReceipts, Error>?
    
    override func throttleAndSendMessageReceipt(event: AmazonConnectChatIOS.MessageReceiptType, messageId: String, completion: @escaping (Result<AmazonConnectChatIOS.PendingMessageReceipts, any Error>) -> Void) {
        
        numThrottleAndSendMessageReceiptCalled += 1
        if !mockThrottleAndSendMessageReceipt {
            super.throttleAndSendMessageReceipt(event: event, messageId: messageId, completion: completion)
            return
        }
        
        if let result = throttleAndSendMessageReceiptResult {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                switch result {
                case .success(let pendingMessageReceipts):
                    completion(.success(pendingMessageReceipts))
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    override func invalidateTimer() {
        numInvalidateTimerCalled += 1
        super.invalidateTimer()
    }
    
    override func handleMessageReceipt(event: AmazonConnectChatIOS.MessageReceiptType, messageId: String) {
        numHandleMessageReceiptCalled += 1
        super.handleMessageReceipt(event: event, messageId: messageId)
    }
}
