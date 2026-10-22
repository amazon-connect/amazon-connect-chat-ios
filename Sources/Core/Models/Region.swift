// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// An AWS region identifier.
///
/// `aws-sdk-swift` expresses regions as plain strings rather than as a closed enum, so this is a
/// thin string wrapper rather than an enum. Any region string is valid, including ones that ship
/// after this version of the SDK:
///
/// ```swift
/// GlobalConfig(region: .usWest2)        // named constant
/// GlobalConfig(region: "us-west-2")     // string literal
/// GlobalConfig(region: Region("us-west-2"))
/// ```
///
/// The named constants below are a convenience only; they are not an authoritative list of the
/// regions in which Amazon Connect is available. Consult the Amazon Connect documentation for
/// current service availability.
public struct Region: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public var description: String { rawValue }
}

// MARK: - Named regions

public extension Region {
    static let usEast1 = Region("us-east-1")
    static let usEast2 = Region("us-east-2")
    static let usWest1 = Region("us-west-1")
    static let usWest2 = Region("us-west-2")
    static let afSouth1 = Region("af-south-1")
    static let apEast1 = Region("ap-east-1")
    static let apNortheast1 = Region("ap-northeast-1")
    static let apNortheast2 = Region("ap-northeast-2")
    static let apNortheast3 = Region("ap-northeast-3")
    static let apSouth1 = Region("ap-south-1")
    static let apSouth2 = Region("ap-south-2")
    static let apSoutheast1 = Region("ap-southeast-1")
    static let apSoutheast2 = Region("ap-southeast-2")
    static let apSoutheast3 = Region("ap-southeast-3")
    static let apSoutheast4 = Region("ap-southeast-4")
    static let apSoutheast5 = Region("ap-southeast-5")
    static let apSoutheast7 = Region("ap-southeast-7")
    static let caCentral1 = Region("ca-central-1")
    static let caWest1 = Region("ca-west-1")
    static let cnNorth1 = Region("cn-north-1")
    static let cnNorthwest1 = Region("cn-northwest-1")
    static let euCentral1 = Region("eu-central-1")
    static let euCentral2 = Region("eu-central-2")
    static let euNorth1 = Region("eu-north-1")
    static let euSouth1 = Region("eu-south-1")
    static let euSouth2 = Region("eu-south-2")
    static let euWest1 = Region("eu-west-1")
    static let euWest2 = Region("eu-west-2")
    static let euWest3 = Region("eu-west-3")
    static let ilCentral1 = Region("il-central-1")
    static let meCentral1 = Region("me-central-1")
    static let meSouth1 = Region("me-south-1")
    static let mxCentral1 = Region("mx-central-1")
    static let saEast1 = Region("sa-east-1")
    static let usGovEast1 = Region("us-gov-east-1")
    static let usGovWest1 = Region("us-gov-west-1")
}

// MARK: - 2.x source compatibility
//
// These mirror the case names of `AWSCore.AWSRegionType` from the deprecated AWS Mobile SDK so
// that call sites such as `GlobalConfig(region: .USWest2)` continue to compile against 3.0.
// They are deprecated in favour of the lowerCamelCase constants above and may be removed in a
// future major version.

public extension Region {
    @available(*, deprecated, renamed: "usEast1")
    static let USEast1 = Region.usEast1
    @available(*, deprecated, renamed: "usEast2")
    static let USEast2 = Region.usEast2
    @available(*, deprecated, renamed: "usWest1")
    static let USWest1 = Region.usWest1
    @available(*, deprecated, renamed: "usWest2")
    static let USWest2 = Region.usWest2
    @available(*, deprecated, renamed: "afSouth1")
    static let AFSouth1 = Region.afSouth1
    @available(*, deprecated, renamed: "apEast1")
    static let APEast1 = Region.apEast1
    @available(*, deprecated, renamed: "apNortheast1")
    static let APNortheast1 = Region.apNortheast1
    @available(*, deprecated, renamed: "apNortheast2")
    static let APNortheast2 = Region.apNortheast2
    @available(*, deprecated, renamed: "apNortheast3")
    static let APNortheast3 = Region.apNortheast3
    @available(*, deprecated, renamed: "apSouth1")
    static let APSouth1 = Region.apSouth1
    @available(*, deprecated, renamed: "apSouth2")
    static let APSouth2 = Region.apSouth2
    @available(*, deprecated, renamed: "apSoutheast1")
    static let APSoutheast1 = Region.apSoutheast1
    @available(*, deprecated, renamed: "apSoutheast2")
    static let APSoutheast2 = Region.apSoutheast2
    @available(*, deprecated, renamed: "apSoutheast3")
    static let APSoutheast3 = Region.apSoutheast3
    @available(*, deprecated, renamed: "apSoutheast4")
    static let APSoutheast4 = Region.apSoutheast4
    @available(*, deprecated, renamed: "apSoutheast5")
    static let APSoutheast5 = Region.apSoutheast5
    @available(*, deprecated, renamed: "apSoutheast7")
    static let APSoutheast7 = Region.apSoutheast7
    @available(*, deprecated, renamed: "caCentral1")
    static let CACentral1 = Region.caCentral1
    @available(*, deprecated, renamed: "caWest1")
    static let CAWest1 = Region.caWest1
    @available(*, deprecated, renamed: "cnNorth1")
    static let CNNorth1 = Region.cnNorth1
    @available(*, deprecated, renamed: "cnNorthwest1")
    static let CNNorthWest1 = Region.cnNorthwest1
    @available(*, deprecated, renamed: "euCentral1")
    static let EUCentral1 = Region.euCentral1
    @available(*, deprecated, renamed: "euCentral2")
    static let EUCentral2 = Region.euCentral2
    @available(*, deprecated, renamed: "euNorth1")
    static let EUNorth1 = Region.euNorth1
    @available(*, deprecated, renamed: "euSouth1")
    static let EUSouth1 = Region.euSouth1
    @available(*, deprecated, renamed: "euSouth2")
    static let EUSouth2 = Region.euSouth2
    @available(*, deprecated, renamed: "euWest1")
    static let EUWest1 = Region.euWest1
    @available(*, deprecated, renamed: "euWest2")
    static let EUWest2 = Region.euWest2
    @available(*, deprecated, renamed: "euWest3")
    static let EUWest3 = Region.euWest3
    @available(*, deprecated, renamed: "ilCentral1")
    static let ILCentral1 = Region.ilCentral1
    @available(*, deprecated, renamed: "meCentral1")
    static let MECentral1 = Region.meCentral1
    @available(*, deprecated, renamed: "meSouth1")
    static let MESouth1 = Region.meSouth1
    @available(*, deprecated, renamed: "mxCentral1")
    static let MXCentral1 = Region.mxCentral1
    @available(*, deprecated, renamed: "saEast1")
    static let SAEast1 = Region.saEast1
    @available(*, deprecated, renamed: "usGovEast1")
    static let USGovEast1 = Region.usGovEast1
    @available(*, deprecated, renamed: "usGovWest1")
    static let USGovWest1 = Region.usGovWest1
}
