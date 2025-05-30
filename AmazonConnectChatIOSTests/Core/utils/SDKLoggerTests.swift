// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import AmazonConnectChatIOS

class MockLogger: SDKLoggerProtocol {
    var loggedMessages: [String] = []

    func logVerbose(_ message: @autoclosure () -> String) {
        loggedMessages.append("VERBOSE: \(message())")
    }

    func logInfo(_ message: @autoclosure () -> String) {
        loggedMessages.append("INFO: \(message())")
    }

    func logDebug(_ message: @autoclosure () -> String) {
        loggedMessages.append("DEBUG: \(message())")
    }

    func logFault(_ message: @autoclosure () -> String) {
        loggedMessages.append("FAULT: \(message())")
    }

    func logError(_ message: @autoclosure () -> String) {
        loggedMessages.append("ERROR: \(message())")
    }
}

class SDKLoggerTests: XCTestCase {
    var mockLogger: MockLogger!

    override func setUp() {
        super.setUp()
        mockLogger = MockLogger()
        SDKLogger.configureLogger(mockLogger)
    }

    override func tearDown() {
        mockLogger = nil
        SDKLogger.isLoggingEnabled = false
        super.tearDown()
    }

    func testLoggingDisabledByDefault() {
        // When
        SDKLogger.logger.logDebug("Test message")

        // Then
        XCTAssertTrue(mockLogger.loggedMessages.isEmpty, "No messages should be logged when logging is disabled")
    }

    func testLoggingWhenEnabled() {
        // Given
        SDKLogger.isLoggingEnabled = true

        // When
        SDKLogger.logger.logDebug("Test debug message")
        SDKLogger.logger.logError("Test error message")

        // Then
        XCTAssertEqual(mockLogger.loggedMessages.count, 2, "Both messages should be logged")
        XCTAssertEqual(mockLogger.loggedMessages[0], "DEBUG: Test debug message")
        XCTAssertEqual(mockLogger.loggedMessages[1], "ERROR: Test error message")
    }

    func testAllLogLevels() {
        // Given
        SDKLogger.isLoggingEnabled = true

        // When
        SDKLogger.logger.logVerbose("Verbose message")
        SDKLogger.logger.logInfo("Info message")
        SDKLogger.logger.logDebug("Debug message")
        SDKLogger.logger.logFault("Fault message")
        SDKLogger.logger.logError("Error message")

        // Then
        XCTAssertEqual(mockLogger.loggedMessages.count, 5, "All messages should be logged")
        XCTAssertEqual(mockLogger.loggedMessages[0], "VERBOSE: Verbose message")
        XCTAssertEqual(mockLogger.loggedMessages[1], "INFO: Info message")
        XCTAssertEqual(mockLogger.loggedMessages[2], "DEBUG: Debug message")
        XCTAssertEqual(mockLogger.loggedMessages[3], "FAULT: Fault message")
        XCTAssertEqual(mockLogger.loggedMessages[4], "ERROR: Error message")
    }

    func testToggleLogging() {
        // Given
        SDKLogger.isLoggingEnabled = true

        // When
        SDKLogger.logger.logDebug("First message")
        SDKLogger.isLoggingEnabled = false
        SDKLogger.logger.logDebug("Second message")
        SDKLogger.isLoggingEnabled = true
        SDKLogger.logger.logDebug("Third message")

        // Then
        XCTAssertEqual(mockLogger.loggedMessages.count, 2, "Only messages when logging is enabled should be logged")
        XCTAssertEqual(mockLogger.loggedMessages[0], "DEBUG: First message")
        XCTAssertEqual(mockLogger.loggedMessages[1], "DEBUG: Third message")
    }
}
