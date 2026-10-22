// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import SmithyHTTPAPI

/// Appends the legacy `AmazonConnect-Mobile Chat-iOS SDK/<version>` product token to the
/// `User-Agent` header of every outgoing request.
///
/// The token contains a space and a slash, which the AWS SDK for Swift's `appID` extension point
/// sanitizes, so `appID` alone cannot reproduce the 2.x `addUserAgentProductToken` value that
/// service-side attribution already keys on. Wrapping the HTTP client is the narrowest seam that
/// runs after the SDK's own user-agent interceptor: the SDK sets `User-Agent` in
/// `modifyBeforeTransmit`, after signing, so amending the header here cannot invalidate the
/// request signature.
final class UserAgentProductTokenHTTPClient: HTTPClient {
    private let base: any HTTPClient
    private let productToken: String

    /// - Parameters:
    ///   - base: The engine that actually transmits the request.
    ///   - productToken: The product token to append to the `User-Agent` header.
    init(wrapping base: any HTTPClient, productToken: String) {
        self.base = base
        self.productToken = productToken
    }

    func send(request: HTTPRequest) async throws -> HTTPResponse {
        // The engine can see the same request instance again on retries, so only append the
        // token when it is not already present.
        if let existing = request.headers.value(for: "User-Agent") {
            if !existing.contains(productToken) {
                request.headers.update(name: "User-Agent", value: "\(existing) \(productToken)")
            }
        } else {
            request.headers.add(name: "User-Agent", value: productToken)
        }
        return try await base.send(request: request)
    }
}
