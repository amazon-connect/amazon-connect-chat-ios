// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct ConnectionDetails {
    let websocketUrl: String?
    let connectionToken: String?
    let expiry: Date?
    
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
