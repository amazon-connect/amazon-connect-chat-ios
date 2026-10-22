// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    var testFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sample.txt")
    var emptyTestFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("empty.txt")

    let testUrl = "https://www.test-endpoint.com"

    override func setUp() {
        super.setUp()
        apiClient = APIClient(httpClient: MockHttpClient())
    }

    override func tearDown() {
        do {
            try FileManager.default.removeItem(at: testFileUrl)
        } catch {}
        super.tearDown()
    }

    // Helper for building the upload response fixture
    private func makeUploadResponse(includeHeaders: Bool, includeUrl: Bool = true) -> StartAttachmentUploadOutput {
        StartAttachmentUploadOutput(
            uploadMetadata: ConnectParticipantClientTypes.UploadMetadata(
                headersToInclude: includeHeaders ? TestConstants.sampleAttachmentHeaders : nil,
                url: includeUrl ? testUrl : nil
            )
        )
    }

    func testUploadAttachment_Success() {
        let expectation = self.expectation(description: "UploadAttachment succeeds")

        let startAttachmentUploadResponse = makeUploadResponse(includeHeaders: true)

        TestUtils.writeSampleTextToUrl(url: testFileUrl)

        apiClient.uploadAttachment(file: testFileUrl, response: startAttachmentUploadResponse) { success, error in
            if success {
                let mockHttpClient = self.apiClient.httpClient as! MockHttpClient
                XCTAssertEqual(mockHttpClient.urlString, self.testUrl)
                XCTAssertEqual(mockHttpClient.headers, TestConstants.sampleAttachmentHttpHeaders)
                XCTAssertNotNil(mockHttpClient.body)
                expectation.fulfill()
            } else if error != nil {
                XCTFail("Expected success, got unexpected failure: \(String(describing: error))")
            } else {
                XCTFail("Expected success, got unexpected failure")
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testUploadAttachment_NoDataFailure() {
        let expectation = self.expectation(description: "UploadAttachment fails due to no data")

        let startAttachmentUploadResponse = makeUploadResponse(includeHeaders: true)

        apiClient.uploadAttachment(file: emptyTestFileUrl, response: startAttachmentUploadResponse) { success, error in
            if success {
                XCTFail("Expected failure, got unexpected success")
            } else if error != nil {
                XCTAssertEqual(error?.localizedDescription, "Unable to read file data")
                expectation.fulfill()
            } else {
                XCTFail("Expected failure with error")
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testUploadAttachment_NoHeadersFailure() {
        let expectation = self.expectation(description: "UploadAttachment fails due to missing headers")

        let startAttachmentUploadResponse = makeUploadResponse(includeHeaders: false)

        TestUtils.writeSampleTextToUrl(url: testFileUrl)

        apiClient.uploadAttachment(file: testFileUrl, response: startAttachmentUploadResponse) { success, error in
            if success {
                XCTFail("Expected failure, got unexpected success")
            } else if error != nil {
                XCTAssertEqual(error?.localizedDescription, "Missing upload metadata headers")
                expectation.fulfill()
            } else {
                XCTFail("Expected failure with error")
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testUploadAttachment_NoUrlFailure() {
        let expectation = self.expectation(description: "UploadAttachment fails due to missing URL")
        let startAttachmentUploadResponse = makeUploadResponse(includeHeaders: true, includeUrl: false)
        TestUtils.writeSampleTextToUrl(url: testFileUrl)

        apiClient.uploadAttachment(file: testFileUrl, response: startAttachmentUploadResponse) { success, error in
            XCTAssertFalse(success)
            XCTAssertEqual(error?.localizedDescription, "Missing attachment upload URL")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
