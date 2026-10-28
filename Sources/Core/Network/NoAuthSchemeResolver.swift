// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant
import Smithy
import SmithyHTTPAPI
import SmithyHTTPAuthAPI

/// Resolves every Connect Participant operation to the `smithy.api#noAuth` scheme so requests are
/// sent unsigned and authorized only by the participant or connection token.
struct NoAuthSchemeResolver: ConnectParticipantAuthSchemeResolver {
    static let noAuthSchemeID = "smithy.api#noAuth"

    struct Parameters: AuthSchemeResolverParameters {
        let operation: String
    }

    func resolveAuthScheme(params: AuthSchemeResolverParameters) throws -> [AuthOption] {
        return [AuthOption(schemeID: Self.noAuthSchemeID)]
    }

    func constructParameters(context: Context) throws -> AuthSchemeResolverParameters {
        guard let operation = context.getOperation() else {
            throw ClientError.dataNotFound("Operation name not configured in middleware context for auth scheme resolver params construction.")
        }
        return Parameters(operation: operation)
    }
}
