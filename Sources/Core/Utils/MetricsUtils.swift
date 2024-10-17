// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0


import Foundation
import AWSConnectParticipant

struct MetricsUtils {
    
    func getCurrentMetricTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = Date()
        let timestamp = formatter.string(from: now)
        return timestamp
    }

    func getMetricsEndpoint() -> String {
        return "https://ieluqbvv.telemetry.connect.us-west-2.amazonaws.com/prod/put-metrics"
    }
    
}
