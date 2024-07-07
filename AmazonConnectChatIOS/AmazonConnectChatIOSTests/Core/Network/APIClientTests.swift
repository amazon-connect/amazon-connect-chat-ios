// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import XCTest
import AWSConnectParticipant
@testable import AmazonConnectChatIOS

class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    var testFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sample.txt")
    var emptyTestFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("empty.txt")
    
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
    
    func testUploadAttachment_Success() {
        let expectation = self.expectation(description: "UploadAttachment succeeds")
        
        let startAttachmentUploadResponse = AWSConnectParticipantStartAttachmentUploadResponse()
        startAttachmentUploadResponse?.uploadMetadata = AWSConnectParticipantUploadMetadata()
        
        let testUrl = "https://www.test-endpoint.com"
        
        startAttachmentUploadResponse?.uploadMetadata?.headersToInclude = TestConstants.sampleAttachmentHeaders
        
        startAttachmentUploadResponse?.uploadMetadata?.url = testUrl
        
        
        TestUtils.writeSampleTextToUrl(url: testFileUrl)
        
        apiClient.uploadAttachment(file: testFileUrl, response: startAttachmentUploadResponse!) { success, error in
            if success {
                let mockHttpClient = self.apiClient.httpClient as! MockHttpClient
                XCTAssertEqual(mockHttpClient.urlString, testUrl)
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
        
        let startAttachmentUploadResponse = AWSConnectParticipantStartAttachmentUploadResponse()
        
        startAttachmentUploadResponse?.uploadMetadata = AWSConnectParticipantUploadMetadata()
        
        let testUrl = "https://www.test-endpoint.com"
        
        startAttachmentUploadResponse?.uploadMetadata?.headersToInclude = TestConstants.sampleAttachmentHeaders
        
        startAttachmentUploadResponse?.uploadMetadata?.url = testUrl
        
        apiClient.uploadAttachment(file: emptyTestFileUrl, response: startAttachmentUploadResponse!) { success, error in
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
        
        let startAttachmentUploadResponse = AWSConnectParticipantStartAttachmentUploadResponse()
        
        startAttachmentUploadResponse?.uploadMetadata = AWSConnectParticipantUploadMetadata()
        
        let testUrl = "https://www.test-endpoint.com"
        
        startAttachmentUploadResponse?.uploadMetadata?.url = testUrl
        
        
        TestUtils.writeSampleTextToUrl(url: testFileUrl)
        
        apiClient.uploadAttachment(file: testFileUrl, response: startAttachmentUploadResponse!) { success, error in
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
}
