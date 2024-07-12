// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
@testable import AmazonConnectChatIOS

class MockConnectionDetailsProvider: ConnectionDetailsProviderProtocol {
    static let shared = MockConnectionDetailsProvider()
    var mockConnectionDetails: ConnectionDetails?
    var mockChatDetails: ChatDetails?
    var isChatActive: Bool = true

    func updateChatDetails(newDetails: ChatDetails) {
        mockChatDetails = newDetails
    }

    func getConnectionDetails() -> ConnectionDetails? {
        return mockConnectionDetails
    }

    func updateConnectionDetails(newDetails: ConnectionDetails) {
        mockConnectionDetails = newDetails
    }

    func getChatDetails() -> ChatDetails? {
        return mockChatDetails
    }
    
    func isChatSessionActive() -> Bool {
        return isChatActive
    }
    
    func setChatSessionState(isActive: Bool) {
        isChatActive = isActive
    }
}
