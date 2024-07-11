// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class MockAPIClient:APIClientProtocol {
    let httpClient: HttpClient
    var mockUploadAttachment = true
    var mockSendMetrics = true
    
    var uploadAttachmentCalled = false
    var sendMetricsCalled = false
    
    init(httpClient: HttpClient = DefaultHttpClient()) {
        self.httpClient = httpClient
    }
    
    func uploadAttachment(file: URL, response: AWSConnectParticipantStartAttachmentUploadResponse, completion: @escaping (Bool, Error?) -> Void) {
        if mockUploadAttachment {
            uploadAttachmentCalled = true
            completion(true, nil)
        }
    }
    
    func sendMetrics(metricsEndpoint: String, metricList: [Metric], completion: @escaping (Result<PutMetricsResponse, Error>) -> Void) -> Void {

    }
}
