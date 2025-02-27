// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSCore

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
    
    func configureMetricsManager(config: GlobalConfig){
        metricsManager.configure(config: config)
    }
    
    func triggerCountMetric(metricName: MetricName) {
        metricsManager.addCountMetric(metricName: metricName)
    }
}

