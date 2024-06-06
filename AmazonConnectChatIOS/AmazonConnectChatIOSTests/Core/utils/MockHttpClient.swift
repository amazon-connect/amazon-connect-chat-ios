//
//  MockHttpClient.swift
//  AmazonConnectChatIOSTests
//

import XCTest
import UniformTypeIdentifiers
import AWSConnectParticipant

@testable import AmazonConnectChatIOS

class MockHttpClient: DefaultHttpClient {
    var urlString: String?
    var headers: HttpHeaders?
    var body: Encodable?

    override func putJson<B: Encodable>(_ urlString: String,
                                        _ headers: HttpHeaders?,
                                        _ body: B,
                                        _ onSuccess: @escaping () -> Void,
                                        _ onFailure: @escaping (_ error: Error) -> Void) {
        self.urlString = urlString
        self.headers = headers
        self.body = body
        onSuccess()
        return
    }
}
