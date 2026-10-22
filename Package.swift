// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AmazonConnectChatIOS",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "AmazonConnectChatIOS",
            targets: ["AmazonConnectChatIOS"]
        ),
    ],
    dependencies: [
        // Do not raise this floor. `amplify-swift` pins `aws-sdk-swift` with `exact:` and that pin
        // moves between releases, so a higher floor trades the issue #86 module collision for an
        // unresolvable graph.
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AmazonConnectChatIOS",
            dependencies: [
                .product(name: "AWSConnectParticipant", package: "aws-sdk-swift"),
                // Supplies StaticAWSCredentialIdentityResolver / AWSCredentialIdentity.
                .product(name: "AWSSDKIdentity", package: "aws-sdk-swift")
            ],
            path: "Sources",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
