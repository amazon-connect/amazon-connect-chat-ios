// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import UniformTypeIdentifiers
import AWSConnectParticipant

@testable import AmazonConnectChatIOS


class MockURLSession: DownloadSessionProtocol {
    var downloadTaskCalled = false
    var mockUrlResult: URL?
    var mockUrlResponse: URLResponse?
    var mockError: (any Error)?

    func makeDownloadTask(
        with url: URL,
        completionHandler: @escaping @Sendable (URL?, URLResponse?, (any Error)?) -> Void
    ) -> any DownloadTaskProtocol {
        downloadTaskCalled = true
        completionHandler(mockUrlResult, mockUrlResponse, mockError)
        return MockURLSessionDownloadTask()
    }
}


class MockURLSessionDownloadTask: DownloadTaskProtocol {
    func resume() {
        // No-op: Do nothing
    }
}
