// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents a view resource containing metadata and content for rendering interactive views
public struct ViewResource {
    /// The unique identifier of the view
    public let id: String?
    
    /// The name of the view
    public let name: String?
    
    /// The Amazon Resource Name (ARN) of the view
    public let arn: String?
    
    /// The version of the view
    public let version: Int?
    
    /// The view content as a dictionary
    public let content: [String: Any]?
    
    public init(id: String?, name: String?, arn: String?, version: Int?, content: [String: Any]?) {
        self.id = id
        self.name = name
        self.arn = arn
        self.version = version
        self.content = content
    }
}
