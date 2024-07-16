// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0


import Foundation
import AWSConnectParticipant

struct MetricsUtils {
    private let config = Config()
    
    func getCurrentMetricTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = Date()
        let timestamp = formatter.string(from: now)
        return timestamp
    }

    func getMetricsEndpoint() -> String {
        if config.isDevMode {
            return "https://f9cskafqk3.execute-api.us-west-2.amazonaws.com/devo/put-metrics"
        } else {
            return "https://ieluqbvv.telemetry.connect.us-west-2.amazonaws.com/prod/put-metrics"
        }
    }
    
    func isCsmDisabled() -> Bool {
        return config.disableCsm
    }
}
