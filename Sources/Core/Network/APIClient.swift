// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AWSConnectParticipant

protocol APIClientProtocol {
    func uploadAttachment(file: URL, response: AWSConnectParticipantStartAttachmentUploadResponse, completion: @escaping (Bool, Error?) -> Void)
    func sendMetrics(metricsEndpoint: String, metricList: [Metric], completion: @escaping (Result<PutMetricsResponse, Error>) -> Void)
}


class APIClient:APIClientProtocol {
    static let shared: APIClient = APIClient(httpClient: DefaultHttpClient())
    let httpClient: HttpClient
    
    init(httpClient: HttpClient = DefaultHttpClient()) {
        self.httpClient = httpClient
    }
    
    func uploadAttachment(file: URL, response: AWSConnectParticipantStartAttachmentUploadResponse, completion: @escaping (Bool, Error?) -> Void) {
        guard let fileData = try? Data(contentsOf: file) else {
            completion(false, NSError(domain: "ChatService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to read file data"]))
            return
        }
        
        guard let headers = response.uploadMetadata?.headersToInclude else {
            completion(false, NSError(domain: "ChatService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing upload metadata headers"]))
            return
        }
        
        let headersToInclude: HttpHeaders = headers.reduce(into: HttpHeaders()) { result, pair in
            if let key = HttpHeader.Key(rawValue: pair.key) {
                result[key] = pair.value
            }
        }

        self.httpClient.putJson((response.uploadMetadata?.url)!, headersToInclude, fileData) {
            completion(true, nil)
        } _: { error in
            completion(false, error)
        }
    }
    
    func sendMetrics(metricsEndpoint: String, metricList: [Metric], completion: @escaping (Result<PutMetricsResponse, Error>) -> Void) -> Void {
        let body = CreateMetricRequestBody(metricList: metricList, metricNamespace: "chat-widget")
        self.httpClient.postJson(metricsEndpoint, nil, body) { (data : PutMetricsResponse) in
            completion(.success(data))
        } _: { error in
            completion(.failure(error))
        }
    }
}
