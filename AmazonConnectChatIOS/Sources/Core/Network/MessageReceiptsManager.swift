// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

protocol MessageReceiptsManagerProtocol {
    var timer: Timer? {get}
    var throttleTime: Double {get set}
    var deliveredThrottleTime: Double {get set}
    var shouldSendMessageReceipts: Bool {get set}
    func throttleAndSendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<PendingMessageReceipts, Error>) -> Void)
    func invalidateTimer() -> Void
    func handleMessageReceipt(event: MessageReceiptType, messageId: String)
}

struct PendingMessageReceipts {
    var deliveredReceiptMessageId: String?
    var readReceiptMessageId: String?
    
    init(readReceiptMessageId: String? = nil, deliveredReceiptMessageId: String? = nil) {
        self.readReceiptMessageId = readReceiptMessageId
        self.deliveredReceiptMessageId = deliveredReceiptMessageId
    }
    
    mutating func clear() {
        deliveredReceiptMessageId = nil
        readReceiptMessageId = nil
    }
    
    mutating func checkAndRemoveDuplicateReceipt() {
        if deliveredReceiptMessageId == readReceiptMessageId {
            deliveredReceiptMessageId = nil
        }
    }
}

class MessageReceiptsManager: MessageReceiptsManagerProtocol {    
    var readReceiptSet = Set<String>()
    var deliveredReceiptSet = Set<String>()
    var pendingMessageReceipts: PendingMessageReceipts = PendingMessageReceipts()
    var timer: Timer?
    var throttleTime: Double = MessageReceipts.defaultReceipts.throttleTime
    var deliveredThrottleTime: Double = 3
    var shouldSendMessageReceipts: Bool = true
    
    func throttleAndSendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<PendingMessageReceipts, Error>) -> Void) {
        if !shouldSendMessageReceipts {
            return
        }

        handleMessageReceipt(event: event, messageId: messageId)
        
        if self.timer == nil || !self.timer!.isValid {
            self.timer = Timer.scheduledTimer(withTimeInterval: throttleTime, repeats: false) { _ in
                self.pendingMessageReceipts.checkAndRemoveDuplicateReceipt()
                completion(.success(self.pendingMessageReceipts))
                self.pendingMessageReceipts.clear()
                self.timer?.invalidate()
            }
        }
    }
    
    func invalidateTimer() {
        timer?.invalidate()
    }
    
    func handleMessageReceipt(event: MessageReceiptType, messageId: String) {
        switch event {
        case .messageDelivered:
            if deliveredReceiptSet.contains(messageId) {
                SDKLogger.logger.logDebug("Delivered receipt already sent for messageId: \(messageId)")
                return
            }
            if self.readReceiptSet.contains(messageId) {
                SDKLogger.logger.logDebug("Read receipt already sent for messageId: \(messageId)")
                return
            }
            deliveredReceiptSet.insert(messageId)
            Timer.scheduledTimer(withTimeInterval: deliveredThrottleTime, repeats: false) { _ in
                if self.readReceiptSet.contains(messageId) {
                    SDKLogger.logger.logDebug("Read receipt already sent for messageId: \(messageId)")
                    return
                } else {
                    SDKLogger.logger.logDebug("Sending Delivered receipt: \(messageId)")
                    self.pendingMessageReceipts.deliveredReceiptMessageId = messageId
                }
            }
            break
        case .messageRead:
            if readReceiptSet.contains(messageId) {
                SDKLogger.logger.logDebug("Read receipt already sent for messageId: \(messageId)")
                return
            }
            SDKLogger.logger.logDebug("Sending read receipt: \(messageId)")
            readReceiptSet.insert(messageId)
            pendingMessageReceipts.readReceiptMessageId = messageId
            break
        }
    }
}
