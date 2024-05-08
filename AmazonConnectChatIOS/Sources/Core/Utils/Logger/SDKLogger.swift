//
//  SDKLogger.swift
//  AmazonConnectChatIOS
//

import Foundation
import OSLog


class SDKLogger: SDKLoggerProtocol {
    
    static let logger = SDKLogger()
    private let osLog: OSLog
    
    private init() {
        osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "SDK.DefaultSubsystem", category: "SDKLogging")
    }
    
    func logVerbose(_ message: @autoclosure () -> String) {
        os_log("%{public}@", log: osLog, type: .default, message())
    }
    
    func logInfo(_ message: @autoclosure () -> String) {
        os_log("%{public}@", log: osLog, type: .info, message())
    }
    
    func logDebug(_ message: @autoclosure () -> String) {
        os_log("%{public}@", log: osLog, type: .debug, message())
    }
    
    func logFault(_ message: @autoclosure () -> String) {
        os_log("%{public}@", log: osLog, type: .fault, message())
    }
    
    func logError(_ message: @autoclosure () -> String) {
        os_log("%{public}@", log: osLog, type: .error, message())
    }
    
}


// How to use
//Logger.shared.logInfo("Application started successfully.")
//Logger.shared.logDebug("User data fetched from the database.")
//Logger.shared.logError("Failed to process user request.")
