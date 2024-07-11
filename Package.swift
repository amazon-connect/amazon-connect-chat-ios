// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "AmazonConnectChatIOS",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AmazonConnectChatIOS",
            targets: ["AmazonConnectChatIOS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm", from: "2.36.4")
    ],
    targets: [
        .target(
            name: "AmazonConnectChatIOS",
            dependencies: [
                .product(name: "AWSCore", package: "aws-sdk-ios-spm"),
                .product(name: "AWSConnectParticipant", package: "aws-sdk-ios-spm")
            ],
            path: "Sources"
            ),
        .binaryTarget(
            name: "AmazonConnectChatIOSSDK",
            path: "./Sources/AmazonConnectChatIOS.xcframework"
        )
    ]
)
