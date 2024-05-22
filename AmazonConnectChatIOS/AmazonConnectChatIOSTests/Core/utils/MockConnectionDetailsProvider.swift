//
//  MockConnectionDetailsProvider.swift
//  AmazonConnectChatIOSTests
//
//  Created by Mittal, Rajat on 5/18/24.
//

import Foundation
@testable import AmazonConnectChatIOS

class MockConnectionDetailsProvider: ConnectionDetailsProviderProtocol {
    static let shared = MockConnectionDetailsProvider()
    var mockConnectionDetails: ConnectionDetails?
    var mockChatDetails: ChatDetails?

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
}
