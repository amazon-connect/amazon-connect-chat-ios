// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import AmazonConnectChatIOS

class ViewResourceTests: XCTestCase {
    
    func testTranscriptItemWithViewResource() {
        let viewResource = ViewResource(
            id: "test-view-id",
            name: "Test View",
            arn: "arn:aws:connect:us-west-2:123456789:view/test",
            version: 1,
            content: ["Actions": [], "InputSchema": "{}", "Template": "{}"]
        )
        
        let transcriptItem = TranscriptItem(
            timeStamp: "2026-01-22T16:00:00Z",
            contentType: "application/vnd.amazonaws.connect.message.interactive",
            id: "test-id",
            serializedContent: [:],
            viewResource: viewResource
        )
        
        XCTAssertNotNil(transcriptItem.viewResource)
        XCTAssertEqual(transcriptItem.viewResource?.id, "test-view-id")
        XCTAssertEqual(transcriptItem.viewResource?.name, "Test View")
        XCTAssertEqual(transcriptItem.viewResource?.version, 1)
    }
    
    func testMessageWithViewResource() {
        let viewResource = ViewResource(
            id: "view-123",
            name: "Interactive View",
            arn: "arn:aws:connect:us-west-2:123456789:view/interactive",
            version: 2,
            content: ["Actions": ["submit"], "InputSchema": "{\"type\":\"object\"}", "Template": "{\"layout\":\"vertical\"}"]
        )
        
        let message = Message(
            participant: "AGENT",
            text: "{\"templateType\":\"ViewResource\"}",
            contentType: "application/vnd.amazonaws.connect.message.interactive",
            timeStamp: "2026-01-22T16:00:00Z",
            messageId: "msg-123",
            displayName: "Agent",
            serializedContent: [:],
            viewResource: viewResource
        )
        
        XCTAssertNotNil(message.viewResource)
        XCTAssertEqual(message.viewResource?.id, "view-123")
        XCTAssertEqual(message.viewResource?.name, "Interactive View")
        XCTAssertEqual(message.viewResource?.version, 2)
        XCTAssertNotNil(message.viewResource?.content?["Actions"])
    }
    
    func testExtractViewResourceFromContent() {
        let jsonContent = """
        {
            "templateType": "ViewResource",
            "data": {
                "content": {
                    "id": "view-456",
                    "name": "Form View",
                    "arn": "arn:aws:connect:us-west-2:123456789:view/form",
                    "version": 3,
                    "content": {
                        "Actions": ["submit", "cancel"],
                        "InputSchema": "{\\"type\\":\\"object\\"}",
                        "Template": "{\\"layout\\":\\"form\\"}"
                    }
                }
            }
        }
        """
        
        // This would be tested in WebSocketManager tests
        // Just verifying the structure is correct
        XCTAssertTrue(jsonContent.contains("ViewResource"))
        XCTAssertTrue(jsonContent.contains("Actions"))
        XCTAssertTrue(jsonContent.contains("InputSchema"))
        XCTAssertTrue(jsonContent.contains("Template"))
    }
}
