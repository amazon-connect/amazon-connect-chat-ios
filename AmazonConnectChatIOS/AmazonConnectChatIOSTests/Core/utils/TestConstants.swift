//
//  TestConstants.swift
//  AmazonConnectChatIOSTests
//
//  Created by Liao, Michael on 6/10/24.
//

@testable import AmazonConnectChatIOS

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
}
