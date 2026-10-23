# Migrating from 2.x to 3.0

Version 3.0 replaces the deprecated AWS Mobile SDK for iOS with the AWS SDK for Swift. This is a
major release because several AWS-owned Objective-C reference types in the public API become Swift
value types.

## 1. Move to Swift Package Manager

CocoaPods is no longer supported. The AWS SDK for Swift does not publish CocoaPods specifications,
so the dependency graph cannot be represented by the 2.x podspec.

In Xcode:

1. Remove `AmazonConnectChatIOS`, `AWSCore`, and the old `AWSConnectParticipant` pod dependencies.
2. Remove the generated Pods integration by following CocoaPods' normal deintegration steps.
3. Choose **File > Add Package Dependencies...**.
4. Add `https://github.com/amazon-connect/amazon-connect-chat-ios`.
5. Select the `AmazonConnectChatIOS` product for your application target.

If you installed the prebuilt `AmazonConnectChatIOS.xcframework` from GitHub Releases, remove it and
the `AWSCore` and `AWSConnectParticipant` frameworks you added alongside it, then follow steps 3-5.
Version 3.0 is not released as a prebuilt XCFramework. The AWS SDK for Swift is distributed only as
Swift package source and its modules are not built with library evolution, so a prebuilt SDK binary
cannot be imported without that exact package graph and would embed a second copy of it.

The package declares `aws-sdk-swift` from `1.6.47`, the oldest release it builds against. Amplify
pins an exact AWS SDK for Swift version, so if your application also uses `amplify-swift`, use
amplify-swift 2.55.0 or later; earlier releases pin an older `aws-sdk-swift` and the package graph
does not resolve.

The AWS SDK for Swift depends on `smithy-swift`, which includes a Swift package plugin. The first
time Xcode builds your app, it asks you to trust and enable that plugin. Command-line and CI builds
that run `xcodebuild` need `-skipPackagePluginValidation`. Select the platform with `-destination`
(for example `-destination "generic/platform=iOS Simulator"`) rather than `-sdk iphonesimulator`:
`-sdk` also applies to the plugin's macOS build tool, and the build fails with
`Build input file cannot be found: .../SmithyCodegenCLI`.

## 2. Remove old AWS Mobile SDK imports

Remove:

```swift
import AWSCore
```

Normal Chat SDK consumers only need:

```swift
import AmazonConnectChatIOS
```

Code that subclasses `AWSClient` and names Connect Participant request or response models also
needs:

```swift
import AWSConnectParticipant
```

## 3. Update region names

`AWSRegionType` is replaced by the Chat SDK's `Region` string wrapper:

```swift
// 2.x
GlobalConfig(region: .USEast1)

// 3.0
GlobalConfig(region: .usEast1)
```

You may also use a string literal for a new region without waiting for an SDK release:

```swift
GlobalConfig(region: "ap-southeast-4")
```

The default remains `us-west-2`.

## 4. Update transcript option types

| 2.x | 3.0 |
| --- | --- |
| `AWSConnectParticipantScanDirection` | `ScanDirection` |
| `.forward` / `.backward` | `.forward` / `.backward` |
| `AWSConnectParticipantSortKey` | `SortKey` |
| `.ascending` / `.descending` | `.ascending` / `.descending` |
| `AWSConnectParticipantStartPosition` | `ConnectParticipantClientTypes.StartPosition` |

The generated `StartPosition` model is a value type. Its `identifier` field is now `id`, and
`mostRecent` is a non-optional `Int` with a default value of `0`, rather than an `NSNumber?`.

## 5. Update custom `AWSClient` subclasses

The callback-based extension point remains available, but generated request and response type names
changed:

| 2.x response/request | 3.0 |
| --- | --- |
| `AWSConnectParticipantCreateParticipantConnectionResponse` | `CreateParticipantConnectionOutput` |
| `AWSConnectParticipantDisconnectParticipantResponse` | `DisconnectParticipantOutput` |
| `AWSConnectParticipantSendMessageResponse` | `SendMessageOutput` |
| `AWSConnectParticipantSendEventResponse` | `SendEventOutput` |
| `AWSConnectParticipantGetTranscriptRequest` | `GetTranscriptInput` |
| `AWSConnectParticipantGetTranscriptResponse` | `GetTranscriptOutput` |
| `AWSConnectParticipantStartAttachmentUploadResponse` | `StartAttachmentUploadOutput` |
| `AWSConnectParticipantCompleteAttachmentUploadResponse` | `CompleteAttachmentUploadOutput` |
| `AWSConnectParticipantGetAttachmentResponse` | `GetAttachmentOutput` |
| `AWSConnectParticipantDescribeViewResponse` | `DescribeViewOutput` |

For example:

```swift
import AmazonConnectChatIOS
import AWSConnectParticipant

final class MyCustomClient: AWSClient {
    override func sendMessage(
        connectionToken: String,
        contentType: ContentType,
        message: String,
        completion: @escaping (Result<SendMessageOutput, Error>) -> Void
    ) {
        super.sendMessage(
            connectionToken: connectionToken,
            contentType: contentType,
            message: message,
            completion: completion
        )
    }
}
```

Deprecated aliases for the 2.x names are included to make the transition easier. They do not make
the old models behavior-compatible: generated models are now value types, and some fields were
renamed. Update new code to the 3.0 names.

## 6. Update generated model field access

The most common generated-model changes are:

| 2.x field | 3.0 field |
| --- | --- |
| `AWSConnectParticipantItem.identifier` | `ConnectParticipantClientTypes.Item.id` |
| `AWSConnectParticipantItem.types` | `ConnectParticipantClientTypes.Item.type` |
| `AWSConnectParticipantStartPosition.identifier` | `ConnectParticipantClientTypes.StartPosition.id` |

The AWS SDK for Swift models use Swift initializers and value semantics. Create a mutable value with
`var` when you need to set fields after initialization.

## 7. Validate your application

Before releasing:

1. Resolve packages with any Amplify dependencies present in the same app.
2. Build and run unit tests.
3. Start a chat and connect to an agent.
4. Send and receive messages, typing events, and read/delivered receipts.
5. Retrieve the transcript.
6. Upload and download attachments.
7. Disconnect and reconnect a chat.

Participant and connection tokens continue to be sent as `X-Amz-Bearer`. As in 2.x, requests are
not SigV4 signed: the Chat SDK resolves every operation to the `smithy.api#noAuth` scheme. It also
supplies empty static credentials so the client never falls back to a device credential chain.

Product attribution is preserved in two forms. The SDK sets the AWS SDK for Swift app ID
extension point, which contributes `app/AmazonConnect-Mobile-Chat-iOS-SDK-3.0.0` to the
User-Agent, and it also appends the exact 2.x product token
`AmazonConnect-Mobile Chat-iOS SDK/<version>` so existing attribution keyed on the legacy token
keeps working. Later releases use the same formats with their current library version.

The signed 2.x XCFramework that was checked into `Sources/` has been removed from the repository.
It contains the deprecated dependency and is not part of 3.0.
