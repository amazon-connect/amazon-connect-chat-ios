// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import OSLog

public class SDKLogger: SDKLoggerProtocol {
    
    static var logger: SDKLoggerProtocol = SDKLogger()
    private let osLog: OSLog
    
    /// Flag to enable/disable logging. Set to false by default.
    public static var isLoggingEnabled: Bool = false

    private init() {
        osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "SDK.DefaultSubsystem", category: "SDKLogging")
    }
    
    public func logVerbose(_ message: @autoclosure () -> String) {
        guard SDKLogger.isLoggingEnabled else { return }
        os_log("%{public}@", log: osLog, type: .default, message())
    }
    
    public func logInfo(_ message: @autoclosure () -> String) {
        guard SDKLogger.isLoggingEnabled else { return }
        os_log("%{public}@", log: osLog, type: .info, message())
    }
    
    public func logDebug(_ message: @autoclosure () -> String) {
        guard SDKLogger.isLoggingEnabled else { return }
        os_log("%{public}@", log: osLog, type: .debug, message())
    }
    
    public func logFault(_ message: @autoclosure () -> String) {
        guard SDKLogger.isLoggingEnabled else { return }
        os_log("%{public}@", log: osLog, type: .fault, message())
    }
    
    public func logError(_ message: @autoclosure () -> String) {
        guard SDKLogger.isLoggingEnabled else { return }
        os_log("%{public}@", log: osLog, type: .error, message())
    }
    
    public static func configureLogger(_ logger: SDKLoggerProtocol) {
        SDKLogger.logger = logger
    }
}
