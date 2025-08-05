// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct ConnectionDetails {
    let websocketUrl: String?
    let connectionToken: String?
    let expiry: Date?
    
    public init(websocketUrl: String?, connectionToken: String?, expiry: Date?) {
        self.websocketUrl = websocketUrl
        self.connectionToken = connectionToken
        self.expiry = expiry
    }
    
    public func getWebsocketUrl() -> String? {
        return websocketUrl
    }
    
    public func getConnectionToken() -> String? {
        return connectionToken
    }
    
    public func getExpiry() -> Date? {
        return expiry
    }
}
