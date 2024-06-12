// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import UniformTypeIdentifiers
import AWSConnectParticipant

@testable import AmazonConnectChatIOS


class MockURLSession: URLSession {
    var downloadTaskCalled = false
    var mockUrlResult: URL?
    var mockUrlResponse: URLResponse?
    var mockError: (any Error)?
    
    override func downloadTask(with url: URL, completionHandler: @escaping @Sendable (URL?, URLResponse?, (any Error)?) -> Void) -> URLSessionDownloadTask {
        completionHandler(mockUrlResult, mockUrlResponse, mockError)
        return MockURLSessionDownloadTask()
    }
}


class MockURLSessionDownloadTask: URLSessionDownloadTask {
    override func resume() {
        // No-op: Do nothing
    }
}
