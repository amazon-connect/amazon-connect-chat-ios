// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import AWSCore

enum MetricCategory: String {
    case API
}

enum Metric: String {
    case Count
}

enum MetricName: String {
    case CreateParticipantConnection
    case SendMessage
}

class MetricsClient {
    public static let shared = MetricsClient()
    private let metricsManager: MetricsManager
    
    init() {
        self.metricsManager = MetricsManager(endpointUrl: MetricsUtils().getMetricsEndpoint())
    }
    
    func triggerCountMetric(metricName: MetricName) {
        metricsManager.addCountMetric(metricName: metricName)
    }
}
