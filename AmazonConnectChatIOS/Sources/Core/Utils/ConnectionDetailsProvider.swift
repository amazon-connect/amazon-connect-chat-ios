// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

class ConnectionDetailsProvider {
    static let shared = ConnectionDetailsProvider()
    private var connectionDetails: ConnectionDetails?
    private var chatDetails: ChatDetails?

    func updateConnectionDetails(newDetails: ConnectionDetails) {
        // Logic to update connection details
        self.connectionDetails = newDetails
    }
    
    func updateChatDetails(newDetails: ChatDetails) {
        self.chatDetails = newDetails
    }

    func getConnectionDetails() -> ConnectionDetails? {
        // Return current connection details
        return self.connectionDetails
    }
    
    func getChatDetails() -> ChatDetails? {
        return self.chatDetails
    }

    // Additional logic to handle connection details lifecycle
}
