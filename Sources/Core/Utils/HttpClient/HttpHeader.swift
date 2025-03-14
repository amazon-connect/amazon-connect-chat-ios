// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0


import Foundation

class HttpHeader {}

extension HttpHeader {
    
    enum Key: String {
        case contentEncoding = "Content-Encoding"
        case contentType = "Content-Type"
        case wafToken = "x-aws-waf-token"
        case amzBearer = "X-Amz-Bearer"
        case amzMetaInitialContactId = "x-amz-meta-initial_contact_id"
        case amzMetaContactId = "x-amz-meta-contact_id"
        case amzMetaOrganizationId = "x-amz-meta-organization_id"
        case amzAcl = "x-amz-acl"
        case contentLength = "Content-Length"
        case contentDisposition = "Content-Disposition"
        case amzMetaAccountId = "x-amz-meta-account_id"
        case amzExpctedBucketOwner = "x-amz-expected-bucket-owner"
    }
}

extension HttpHeader {
    
    enum Value: String {
        case amzEncoding = "amz-1.0"
        case jsonContentType = "Application/json"
    }
}
