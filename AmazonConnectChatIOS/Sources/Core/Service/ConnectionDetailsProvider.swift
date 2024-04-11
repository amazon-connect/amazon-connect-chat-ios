//
//  ConnectionDetailsProvider.swift
//  AmazonConnectChatIOS
//
//  Created by Mittal, Rajat on 4/10/24.
//

import Foundation

class ConnectionDetailsProvider {
    static let shared = ConnectionDetailsProvider()
    private var connectionDetails: ConnectionDetails?

    func updateConnectionDetails(newDetails: ConnectionDetails) {
        // Logic to update connection details
        self.connectionDetails = newDetails
    }

    func getConnectionDetails() -> ConnectionDetails? {
        // Return current connection details
        return self.connectionDetails
    }

    // Additional logic to handle connection details lifecycle
}
