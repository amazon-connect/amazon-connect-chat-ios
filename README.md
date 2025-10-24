# Amazon Connect Chat SDK for iOS

> **Note**: This is a test update for demonstration purposes.

## Table of Contents
* [About](#about)
* [Installation Steps](#installation-steps)
* [Getting Started](#getting-started)
  * [How to receive messages](#how-to-receive-messages)
* [API List](#api-list)
  * [GlobalConfig](#globalconfig)
    * [GlobalConfig.init](#globalconfiginit)
    * [Updating configuration](#updating-configuration)
  * [SDKLogger](#sdklogger)
  * [ChatSession APIs](#chatsession-apis)
  * [ChatSession Events](#chatsession-events)
  * [Classes and Structs](#classes-and-structs)
* [Security](#security)
* [License](#license)

## About
The Amazon Connect Chat SDK for iOS is a Swift library that gives you the power to easily integrate Amazon Connect Chat directly into your native iOS applications. The Amazon Connect Chat SDK helps handle client side chat logic and back-end communications similar to the [Amazon Connect ChatJS Library](https://github.com/amazon-connect/amazon-connect-chatjs). The SDK wraps the [Amazon Connect Participant Service](https://docs.aws.amazon.com/connect/latest/APIReference/API_Operations_Amazon_Connect_Participant_Service.html) APIs and abstracts away the management of the chat session and WebSocket.  This allows you to focus on the user interface and experience while relying on the Amazon Connect Chat SDK to interact with all the back-end services.  This approach still requires using your own chat back end to call the Amazon Connect [StartChatContact](https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContact.html) API to initiate contact. You can read instructions on how to quickly set up a StartChatContact Lambda from our [startChatContactAPI](https://github.com/amazon-connect/amazon-connect-chat-ui-examples/tree/master/cloudformationTemplates/startChatContactAPI) example.

## Installation Steps
There are three options to install the Amazon Connect Chat SDK for iOS to your xCode project:

### Install via [Cocoapods](https://cocoapods.org/)

In your `Podfile`:
```
    * Reference the AmazonConnectChatIOS pod in your Podfile
    * target 'YourProject' do
            pod 'AmazonConnectChatIOS'
            ...
        end
```
Then run `pod install` in your project's root directory

### Install via [Swift Package Manager](https://www.swift.org/documentation/package-manager/)
 * Open your project in Xcode
 * Go to **File > Add Package Dependencies...**
 * In the field **Enter package repository URL**, enter "https://github.com/amazon-connect/amazon-connect-chat-ios".
 * Select the desired target project and click **Add Package**

### Download Binaries Directly from GitHub Releases

1. Go to the [Amazon Connect Chat SDK for iOS GitHub Releases](https://github.com/amazon-connect/amazon-connect-chat-ios/releases) page.
2. Download the latest release of the `AmazonConnectChatIOS.xcframework`.
3. Unzip the downloaded file, if necessary.
4. Drag and drop the `AmazonConnectChatIOS.xcframework` into your Xcode project.

>⚠️ Important: Please remember to add 'AWSCore' and 'AWSConnectParticipant' from [AWS IOS SDK](https://github.com/aws-amplify/aws-sdk-ios) while using binaries.


#### How to Import the XCFramework

Once you have added the `AmazonConnectChatIOS.xcframework` to your project, you need to import it into your code. Here are the steps:

1. **Import the Framework in Your Swift Code**:
    ```swift
    import AmazonConnectChatIOS
    ```

By following these steps, you can integrate the Amazon Connect Chat SDK for iOS into your project using CocoaPods, Swift Package Manager, or by directly adding the XCFramework. Make sure to follow the specific installation instructions for each method to ensure a smooth setup process.

## Getting Started

The first step to leveraging the Amazon Connect Chat SDK after installation is to import the library into your file. Next, let's call the StartChatContact API and pass the response details into the SDK's ChatSession object.  Here is an [example](https://github.com/amazon-connect/amazon-connect-chat-ui-examples/blob/master/mobileChatExamples/iOSChatExample/AmazonConnectChatIOSDemo/Models/ChatManager.swift#L137C18-L137C34) of how we would set this up in Swift. For reference, you can visit the [iOSChatExample demo](https://github.com/amazon-connect/amazon-connect-chat-ui-examples/tree/master/mobileChatExamples/iOSChatExample) within the [Amazon Connect Chat UI Examples](https://github.com/amazon-connect/amazon-connect-chat-ui-examples/tree/master) GitHub repository.

The majority of the SDKs functionality will be accessed through the ChatSession object. In order to use this object in the file, we have to first import the AmazonConnectChatIOS library via:

```
import AmazonConnectChatIOS
```

Next, we can create a ChatManager class that helps bridge UI and SDK communication.  This class should be responsible for managing interactions with the ChatSession object. We can either add it as a class property or reference it directly using ChatSession.shared. 

```
class ChatManager: ObservableObject {
    private var chatSession = ChatSession.shared

    ...
```

Before using the chatSession object, we need to set the config for it via the GlobalConfig object.  Most importantly, the GlobalConfig object will be used to set the AWS region that your Connect instance lives in.  Here is an example of how to configure the ChatSession object:

```
init() {
    let globalConfig = GlobalConfig(region: .USEast1)
    self.chatSession = ChatSession.shared
    chatSession.configure(config: globalConfig)
    ...
}
```

From here, you are now ready to interact with the chat via the `ChatSession` object.

### How to receive messages

The Amazon Connect Chat SDK for iOS provides two methods to receive messages.

1. Use [ChatSession.onTranscriptUpdated](#chatsessionontranscriptupdated)
  * This event will pass back the entire transcript every time the transcript is updated. This will return the transcript via an array of [TranscriptItem](#transcriptitem)

2. Use [ChatSession.onMessageReceived](#chatsessiononmessagereceived)
  * This event will pass back each message that is received by the WebSocket.  The event handler will be passed a single [TranscriptItem](#transcriptitem).

### How to handle events

The SDK provides event callbacks for chat experiences:

```swift
// Typing indicators
chatSession.onTyping = { event in
    print("Participant \(event.participant!) is typing...")
    // Show typing indicator in UI
}

// Message receipts
chatSession.onReadReceipt = { event in
    print("Message \(event.id) was read by participant \(event.participant!)")
    // Update message status to "Read"
}

chatSession.onDeliveredReceipt = { event in
    print("Message \(event.id) was delivered to participant \(event.participant!)")
    // Update message status to "Delivered"
}

// Participant state changes
chatSession.onParticipantIdle = { event in
    print("Participant \(event.displayName!) went idle")
    // Show idle indicator
}

chatSession.onParticipantReturned = { event in
    print("Participant \(event.displayName!) returned")
    // Hide idle indicator
}

// Chat lifecycle events
chatSession.onChatRehydrated = { event in
    print("Chat session restored from previous session")
    // Handle chat restoration
}
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.