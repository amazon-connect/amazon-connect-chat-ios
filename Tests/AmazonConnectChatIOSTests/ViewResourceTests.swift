// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import AmazonConnectChatIOS

class ViewResourceTests: XCTestCase {
    
    func testViewResourceContentDecode() {
        let jsonContent = """
        {
            "templateType": "ViewResource",
            "data": {
                "content": {
                    "viewId": "view-123",
                    "Actions": ["submit", "cancel"],
                    "InputSchema": "{}",
                    "Template": "{}"
                }
            }
        }
        """
        
        let content = ViewResourceContent.decode(from: jsonContent)
        XCTAssertNotNil(content)
        
        let viewContent = content as? ViewResourceContent
        XCTAssertNotNil(viewContent)
        XCTAssertEqual(viewContent?.viewId, "view-123")
        XCTAssertNotNil(viewContent?.content?["Actions"])
    }
    
    func testMessageWithInteractiveContentReturnsViewResourceContent() {
        let jsonContent = """
        {
            "templateType": "ViewResource",
            "data": {
                "content": {
                    "viewId": "view-456",
                    "Actions": ["submit"],
                    "InputSchema": "{}",
                    "Template": "{}"
                }
            }
        }
        """
        
        let message = Message(
            participant: "AGENT",
            text: jsonContent,
            contentType: "application/vnd.amazonaws.connect.message.interactive",
            timeStamp: "2026-01-22T16:00:00Z",
            messageId: "msg-123",
            displayName: "Agent",
            serializedContent: [:]
        )
        
        let content = message.content
        XCTAssertNotNil(content)
        XCTAssertTrue(content is ViewResourceContent)
        
        let viewContent = content as? ViewResourceContent
        XCTAssertEqual(viewContent?.viewId, "view-456")
    }
    
    func testViewResourceContentTemplateType() {
        XCTAssertEqual(ViewResourceContent.templateType, "ViewResource")
    }
}
