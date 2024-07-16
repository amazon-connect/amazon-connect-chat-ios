// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation

class MetricsManager {
    var apiClient: APIClientProtocol = APIClient.shared
    private let endpointUrl: String
    private var timer: Timer?
    private var metricList: [Metric]
    private var isMonitoring: Bool = false
    private var shouldRetry: Bool = true

    init(endpointUrl: String) {
        self.endpointUrl = endpointUrl
        self.metricList = []
        if !MetricsUtils().isCsmDisabled() {
            monitorAndSendMetrics()
        }
    }
    
    deinit {
        self.timer?.invalidate()
    }
    
    private func monitorAndSendMetrics() {
        if self.isMonitoring {
            return
        }
        self.isMonitoring = true
        self.timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            if !self.metricList.isEmpty {
                self.apiClient.sendMetrics(metricsEndpoint: self.endpointUrl, metricList: self.metricList) { result in
                    switch result {
                    case .success:
                        self.metricList = []
                        self.isMonitoring = false
                        self.timer?.invalidate()
                    case .failure(_):
                        if self.shouldRetry {
                            self.shouldRetry = false
                        } else {
                            self.isMonitoring = false
                            self.shouldRetry = true
                            self.timer?.invalidate()
                        }
                    }
                }
            }
        }
    }
    
    private func getCountMetricDimensions() -> [Dimension] {
        let countMetricDimensions = [
                Dimension(name: "WidgetType", value: "MobileChatSDK"),
                Dimension(name: "SDKPlatform", value: "iOS"),
                Dimension(name: "Category", value: "API"),
                Dimension(name: "Metric", value: "Count"),
            ]
        return countMetricDimensions
    }
    
    func addCountMetric(metricName: MetricName) -> Void {
        let currentTime = MetricsUtils().getCurrentMetricTimestamp()
        let countMetricDimensions = getCountMetricDimensions()
        let countMetric = Metric(
            dimensions: countMetricDimensions,
            metricName: metricName.rawValue,
            namespace: "chat-widget",
            optionalDimensions: [],
            timestamp: currentTime,
            unit: "Count",
            value: 1)
        
        self.addMetric(metric: countMetric)
    }
    
    func addMetric(metric: Metric) {
        if MetricsUtils().isCsmDisabled() {
            return
        }
        
        self.metricList.insert(metric, at: 0)
        self.monitorAndSendMetrics()
    }
}

struct Metric: Codable {
    let dimensions: [Dimension]
    let metricName: String
    let namespace: String
    let optionalDimensions: [Dimension]
    let timestamp: String // or Date if you want to decode dates automatically
    let unit: String
    let value: Int
}

struct Dimension: Codable {
    let name: String
    let value: String
}

struct CreateMetricRequestBody: Codable {
    let metricList: [Metric]
    let metricNamespace: String
}

struct PutMetricsResponse: Codable {
    let unsetToken: Bool
}
