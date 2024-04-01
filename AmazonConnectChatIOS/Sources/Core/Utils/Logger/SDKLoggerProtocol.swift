//
//  SDKLoggerProtocol.swift
//  AmazonConnectChatIOS
//


import Foundation

protocol SDKLoggerProtocol {
    func logVerbose(
        _ message: @autoclosure () -> String
    )
    func logInfo(
        _ message: @autoclosure () -> String
    )
    func logDebug(
        _ message: @autoclosure () -> String
    )
    func logFault(
        _ message: @autoclosure () -> String
    )
    func logError(
        _ message: @autoclosure () -> String
    )
}
