// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

@testable import AmazonConnectChatIOS

struct TestUtils {
    static func writeSampleTextToUrl(url: URL) {
        let fileContents = "Sample text file contents"
        do {
            try fileContents.write(to: url, atomically: true, encoding: .utf8)
            print("File created successfully at: \(url.path)")
        } catch {
            print("Failed to create file: \(error.localizedDescription)")
            return
        }
    }
}

struct TestConstants {
    static let sampleAttachmentHeaders = [
        "x-amz-meta-contact_id": "12345",
        "x-amz-meta-initial_contact_id": "12345",
        "x-amz-acl": "bucket-owner-full-control",
        "Content-Disposition": "attachment; filename=\"sample.txt\"",
        "x-amz-meta-account_id": "12345",
        "Content-Length": "12345",
        "Content-Type": "text/plain",
        "x-amz-meta-organization_id": "12345"
    ]
    
    static let sampleAttachmentHttpHeaders: HttpHeaders = [
        HttpHeaders.Key.amzMetaContactId: "12345",
        HttpHeaders.Key.amzMetaInitialContactId: "12345",
        HttpHeaders.Key.amzAcl: "bucket-owner-full-control",
        HttpHeaders.Key.contentDisposition: "attachment; filename=\"sample.txt\"",
        HttpHeaders.Key.amzMetaAccountId: "12345",
        HttpHeaders.Key.contentLength: "12345",
        HttpHeaders.Key.contentType: "text/plain",
        HttpHeaders.Key.amzMetaOrganizationId: "12345"
    ]
    
    static let testFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sample.txt")
}
