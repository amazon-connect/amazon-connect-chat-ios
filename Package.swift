// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AmazonConnectChatIOS",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AmazonConnectChatIOS",
            targets: ["AmazonConnectChatIOS"]
        ),
    ],
    dependencies: [
        // 1.6.47 is the oldest release this code builds against: it introduced
        // `ConnectParticipantClient.ConnectParticipantClientConfig`, used in AWSClient. Keep the floor
        // no higher than needed, because `amplify-swift` pins `aws-sdk-swift` with `exact:`;
        // amplify-swift 2.55.0 (aws-sdk-swift 1.6.71) is the oldest compatible release.
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "1.6.47")
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
