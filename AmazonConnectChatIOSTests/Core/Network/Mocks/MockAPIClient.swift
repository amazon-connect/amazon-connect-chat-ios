// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAPIClient:APIClientProtocol {
    let httpClient: HttpClient
    var mockSendMetrics = true
    
    var uploadAttachmentCalled = false
    var sendMetricsCalled = false
    var uploadAttachmentResult: (Bool, Error?) = (true, nil)
    
    init(httpClient: HttpClient = DefaultHttpClient()) {
        self.httpClient = httpClient
    }
    
    func uploadAttachment(file: URL, response: StartAttachmentUploadOutput, completion: @escaping (Bool, Error?) -> Void) {
        uploadAttachmentCalled = true
        completion(uploadAttachmentResult.0, uploadAttachmentResult.1)
    }
    
    func sendMetrics(metricsEndpoint: String, metricList: [Metric], completion: @escaping (Result<PutMetricsResponse, Error>) -> Void) -> Void {

    }
}
