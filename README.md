# Amazon Connect Chat SDK for iOS

## Table of Contents
* [About](#about)
* [Installation Steps](#installation-steps)
* [Getting Started](#getting-started)
  * [How to receive messages](#how-to-receive-messages)
* [API List](#api-list)
  * [GlobalConfig](#globalconfig)
    * [GlobalConfig.init](#globalconfiginit)
    * [Updating configuration](#updating-configuration)
  * [ChatSession APIs](#chatsession-apis)
  * [ChatSession Events](#chatsession-events)
  * [Classes and Structs](#classes-and-structs)
* [Security](#security)
* [License](#license)

## About
The Amazon Connect Chat SDK for iOS is a Swift library that gives you the power to easily integrate Amazon Connect Chat directly into your native iOS applications. The Amazon Connect Chat SDK helps handle client side chat logic and back-end communications similar to the [Amazon Connect ChatJS Library](https://github.com/amazon-connect/amazon-connect-chatjs). The SDK wraps the [Amazon Connect Participant Service](https://docs.aws.amazon.com/connect/latest/APIReference/API_Operations_Amazon_Connect_Participant_Service.html) APIs and abstracts away the management of the chat session and WebSocket.  This allows you to focus on the user interface and experience while relying on the Amazon Connect Chat SDK to interact with all the back-end services.  This approach still requires using your own chat back end to call the Amazon Connect [StartChatContact](https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContact.html) API to initiate contact. You can read instructions on how to quickly set up a StartChatContact Lambda from our [startChatContactAPI](https://github.com/amazon-connect/amazon-connect-chat-ui-examples/tree/master/cloudformationTemplates/startChatContactAPI) example.

## Installation Steps
There are three options to install the Amazon Connect Chat SDK for iOS to your xCode project:

1. Install via [Cocoapods](https://cocoapods.org/)

In your `Podfile`:
```
    * Reference the AmazonConnectChatIOS pod in your Podfile
    * target 'YourProject' do
            pod 'AmazonConnectChatIOS'
            ...
        end
```
Then run `pod install` in your project's root directory

2. Install via [Swift Package Manager](https://www.swift.org/documentation/package-manager/)
    * Open your project in Xcode
    * Go to **File > Add Package Dependencies...**
    * In the field **Enter package repository URL**, enter “https://github.com/amazon-connect/amazon-connect-chat-ios".
    * Select the desired target project and click **Add Package**

3. Download binaries directly from the Amazon Connect Chat SDK for iOS GitHub Releases page

## Getting Started

The first step to leveraging the Amazon Connect Chat SDK after installation is to import the library into your file. The first step is to call the StartChatContact API and pass the response details into the SDK’s ChatSession object.  Here are some examples of how we would set this up in Swift. For reference, you can visit the [iOSChatExample demo](https://github.com/amazon-connect/amazon-connect-chat-ui-examples/tree/master/mobileChatExamples/iOSChatExample) within the [Amazon Connect Chat UI Examples](https://github.com/amazon-connect/amazon-connect-chat-ui-examples/tree/master) GitHub repository.

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

1. Use [ChatSession.onTranscriptUpdated](chatsessionontranscriptupdated)
  * This event will pass back the entire transcript every time the transcript is updated. This will return the transcript via an array of [TranscriptItem](#transcriptitem)

2. Use [ChatSession.onMessageReceived](#chatsessionontranscriptupdated)
  * This event will pass back each message that is received by the WebSocket.  The event handler will be passed a single [TranscriptItem](#transcriptitem).

## API List

### GlobalConfig
The `GlobalConfig` object is used to configure both the AWS ConnectParticipant client as well as some of the chat behavior.

#### `GlobalConfig.init`
The initializer for the `GlobalConfig` object takes in the `AWSRegionType` and the enabled `Features`

```
public struct GlobalConfig {
    public var region: AWSRegionType
    public var features: Features

    public static var defaultRegion: AWSRegionType {
        return Constants.DEFAULT_REGION
    }

    // Initializes a new global configuration with optional custom settings or defaults
    public init(region: AWSRegionType = defaultRegion, features: Features = .defaultFeatures) {
        self.region = region
        self.features = features
    }
}
```
* `region`
  * This property is used to set the region of the ConnectParticipant client.  This should be set to the region of your Connect instance (e.g. `.USEast1`)
  * Type: `AWSRegionType`
* `features: Features`
  * The features property dictates the enablement of certain features as well as their configurations. If no value is passed for this property, the chat will be configured with default values. See [Features](#features) for more details.
  * Type: [Features](#features)
 
#### Updating configuration
If you have set the `GlobalConfig` object or want to update the configurations, you can call `ChatSession.configure` to update the config object.

```
let globalConfig = GlobalConfig(region: .USEast1)
chatSession.configure(config: globalConfig)
```

--------------------

### ChatSession APIs

#### `ChatSession.configure`
Configures the chat service with a `GlobalConfiguration` object.

```
func configure(config: GlobalConfig)
```
* `config`
  * The global configuration to use
  * Type: [GlobalConfig](#globalconfig)

--------------------

#### `ChatSession.connect`
Attempts to connect to a chat session with the given details.

```
func connect(chatDetails: ChatDetails, completion: @escaping (Result<Void, Error>) -> Void)

public struct ChatDetails {
    var contactId: String?
    var participantId: String?
    var participantToken: String
}
```

* `chatDetails`
  * The details of the chat session to connect to. `ChatDetails` data is extracted from `StartChatContact` response.
  * Type: `ChatDetails`
* `completion`
  * The completion handler to call when the connect operation is complete.
  * Type: `(Result<Void, Error>) -> Void`

--------------------

#### `ChatSession.disconnect`
Disconnects the current chat session.

```
func disconnect(completion: @escaping (Result<Void, Error>) -> Void)
```

* `completion`
  * The completion handler to call when the disconnect operation is complete.
  * Type: `(Result<Void, Error>) -> Void`

--------------------

#### `ChatSession.sendMessage`
Sends a message within the chat session.

```
func sendMessage(contentType: ContentType, message: String, completion: @escaping (Result<Void, Error>) -> Void)
```

* `contentType`
  * The type of the message content.
  * Type: [ContentType](#contenttype)
* `message`
  * The message to send.
  * Type: `String`
* `completion`
  * The completion handler to call when the send operation is complete.
  * Type: `(Result<Void, Error>) -> Void`


--------------------

#### `ChatSession.sendEvent`
Sends an event within the chat session.

```
func sendEvent(event: ContentType, content: String, completion: @escaping (Result<Void, Error>) -> Void)
```

* `event`
  * The type of the event content.
  * Type: [ContentType](#contenttype)
* `content`
  * The event content to send.
  * Type: `String`
* `completion`
  * The completion handler to call when the send operation is complete.
  * Type: `(Result<Void, Error>) -> Void`


--------------------

#### `ChatSession.sendMessageReceipt`
Sends read receipt for a message.

```
func sendMessageReceipt(event: MessageReceiptType, messageId: String, completion: @escaping (Result<Void, Error>) -> Void)
```

* `event`
  * The type of read receipt to send (either `.messageDelivered` or `.messageRead`
  * Type: [MessageReceiptType](#messagereceipttype)
  * Default: `.messageRead`
* `messageId`
  * The ID of the message to acknowledge.
  * Type: `String`    
* `completion`
  * The completion handler to call when the send operation is complete.
  * Type: `(Result<Void, Error>) -> Void`


--------------------

#### `ChatSession.getTranscript`
Retrieves the chat transcript.

```
func getTranscript(scanDirection: AWSConnectParticipantScanDirection?, sortOrder: AWSConnectParticipantSortKey?, maxResults: NSNumber?, nextToken: String?, startPosition: AWSConnectParticipantStartPosition?, completion: @escaping (Result<TranscriptResponse, Error>) -> Void)
```

* `scanDirection`
  * The direction to scan the transcript.
  * Type: `AWSConnectParticipantScanDirection?` (String: `'FORWARD' | 'BACKWARD'`) 
  * Default: `BACKWARD`
* `sortOrder`
  * The order to sort the transcript.
  * Type: `AWSConnectParticipantSortKey?` (String: `'DESCENDING | 'ASCENDING'`)
  * Default: `ASCENDING`
* `maxResults`
  * The maximum number of results to retrieve.
  * Type: `NSNumber?`
  * Default: `15`
* `nextToken`
  * Type: `String`
  * The token for the next set of results.
* `startPosition`
  * The start position for the transcript.
  * Type: `AWSConnectParticipantStartPosition?`. See [StartPosition](https://docs.aws.amazon.com/connect/latest/APIReference/API_connect-participant_StartPosition.html)
* `completion`
  * The completion handler to call when the transcript retrieval is complete.
  * Type: (Result<[TranscriptResponse](#transcriptresponse), Error>) -> Void

--------------------

#### `ChatSession.sendAttachment`
Sends an attachment within the chat session.

```
func sendAttachment(file: URL, completion: @escaping (Result<Void, Error>) -> Void)
```

* `file`
  * The URL of the file to attach.
  * Type: `URL`
* `completion`
  * The completion handler to call when the send operation is complete.
  * Type: `(Result<Void, Error>) -> Void`

--------------------

#### `ChatSession.downloadAttachment`
Downloads an attachment to the app's temporary directory given an attachment ID.

```
func downloadAttachment(attachmentId: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void)
```

* `attachmentId`
  * The ID of the attachment to download.
  * Type: `String`
* `filename`
  * The name of the file to save the attachment as.
  * Type: `String`
* `completion`
  * The completion handler to call when the download operation is complete.
  * Type: `(Result<URL, Error>) -> Void`

--------------------

#### `ChatSession.getAttachmentDownloadUrl`
Returns the download URL link for the given attachment ID.

```
func getAttachmentDownloadUrl(attachmentId: String, completion: @escaping (Result<URL, Error>) -> Void)
```

* `attachmentId`
  * The ID of the attachment.
  * Type: `String`
* `completion`
  * The completion handler to call when the URL retrieval is complete.
  * Type: `(Result<URL, Error>) -> Void`

--------------------

#### `ChatSession.isChatSessionActive`
Returns a boolean indicating whether the chat session is still active.

```
func isChatSessionActive() -> Bool
```

--------------------

### ChatSession Events

#### `ChatSession.onConnectionEstablished`
Callback for when the connection is established.

```
var onConnectionEstablished: (() -> Void)? { get set }
```

--------------------

#### `ChatSession.onConnectionBroken`
Callback for when the connection is broken.

```
var onConnectionBroken: (() -> Void)? { get set }
```

--------------------

#### `ChatSession.onMessageReceived`
Callback for when a WebSocket message is received. See [TranscriptItem](#transcriptitem).

```
var onMessageReceived: ((TranscriptItem) -> Void)? { get set }
```
--------------------

#### `ChatSession.onTranscriptUpdated`
Callback for when the transcript is updated. See [TranscriptItem](#transcriptitem)

```
var onTranscriptUpdated: (([TranscriptItem]) -> Void)? { get set }
```

--------------------

#### `ChatSession.onChatEnded`
Callback for when the chat ends.

```
var onChatEnded: (() -> Void)? { get set }
```
--------------------

#### `ChatSession.onDeepHeartbeatFailure`
Callback for when the WebSocket heartbeat is missed.

```
var onDeepHeartbeatFailure: (() -> Void)? { get set }
```
--------------------

#### `ChatSession.onConnectionReEstablished`
Callback for when the connection is re-established.

```
var onConnectionReEstablished: (() -> Void)? { get set }
```
--------------------

## Classes and Structs

### Features
Features are a list of optional chat functions that users may choose to enable, disable or reconfigure.

```
public struct Features {
    public var messageReceipts: MessageReceipts

    // Provides default Features configuration
    public static var defaultFeatures: Features {
        return Features(messageReceipts: .defaultReceipts)
    }

    public init(messageReceipts: MessageReceipts = .defaultReceipts) {
        self.messageReceipts = messageReceipts
    }
}
```

the default value for `Features` will contain the default values for all containing features.

--------------------

### Message Receipts
This feature enables the use of `Read` and `Delivered` receipts for messages. This is used to indicate whether agents have read texts that the client has sent and vice versa.

```
public struct MessageReceipts {
    public var shouldSendMessageReceipts: Bool
    public var throttleTime: Double
    
    // Provides default MessageReceipts configuration
    public static var defaultReceipts: MessageReceipts {
        return MessageReceipts(shouldSendMessageReceipts: true, throttleTime: Constants.MESSAGE_RECEIPT_THROTTLE_TIME)
    }
    
    public init(shouldSendMessageReceipts: Bool, throttleTime: Double) {
        self.shouldSendMessageReceipts = shouldSendMessageReceipts
        self.throttleTime = throttleTime
    }
}
```
* `shouldSendMessageReceipts`
  * Type: `Bool`
  * This is the flag that dictates whether message receipts will be sent from the client side.  Note that this will not block message receipt events from being sent from the agent.
  * Default: `true`
* `throttleTime`
  * Type: `Double`
  * This is used to determine how long to throttle message receipt events before firing them. We recommend having at least some throttling time before each event to reduce unecessary network requests
  * Default: `5.0`

--------------------
### ChatDetails

```
public struct ChatDetails {
    var contactId: String?
    var participantId: String?
    var participantToken: String
}
```
* `contactId`
  * Contact identifier received via [StartChatContact](https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContact.html) response
  * Type: `String`
* `particpantId`
  * Participant identifier received via [StartChatContact](https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContact.html) response
  * Type: `String`
* `participantToken`
  * Participant token received via [StartChatContact](https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContact.html) response
  * Type: `String`
---------------------
### ContentType

`ContentType` describe the type of events and messages that come through the WebSocket.

```
public enum ContentType: String {
    case typing = "application/vnd.amazonaws.connect.event.typing"
    case connectionAcknowledged = "application/vnd.amazonaws.connect.event.connection.acknowledged"
    case messageDelivered = "application/vnd.amazonaws.connect.event.message.delivered"
    case messageRead = "application/vnd.amazonaws.connect.event.message.read"
    case metaData = "application/vnd.amazonaws.connect.event.message.metadata"
    case joined = "application/vnd.amazonaws.connect.event.participant.joined"
    case left = "application/vnd.amazonaws.connect.event.participant.left"
    case ended = "application/vnd.amazonaws.connect.event.chat.ended"
    case plainText = "text/plain"
    case richText = "text/markdown"
    case interactiveText = "application/vnd.amazonaws.connect.message.interactive"
}
```
--------------------
### MessageReceiptType

`MessageReceiptType` is a subset of [ContentType](#contenttype) for message receipt related events.

```
public enum MessageReceiptType: String {
    case messageDelivered = "application/vnd.amazonaws.connect.event.message.delivered"
    case messageRead = "application/vnd.amazonaws.connect.event.message.read"
}
```
--------------------
### TranscriptResponse

```
public class TranscriptResponse: Equatable {
    public let initialContactId: String
    public let nextToken: String
    public var transcript: [TranscriptItem]
}
```
* `initialContactId`
  * This is the id of the chat contact
  * Type: `String`
* `nextToken`
  * The `nextToken` is used to retrieve the next batch of messages from the server. This can be passed into [ChatSession.getTranscript](#chatsessiongettranscript)
  * Type: `String`
* `transcript`
  * This contains the messages that were loaded
  * Type: Array of [TranscriptItem](#transcriptitem)
-------------------
### TranscriptItem
This is the base class for all renderable messages in the transcript.

```
public class TranscriptItem: TranscriptItemProtocol {
    public var id: String
    public var timeStamp: String
    public var contentType: String
    public var serializedContent: [String: Any]?
```
* `id`
  * Id for the message. Unique to each message in the transcript.
  * Type: `String`
* `timeStamp`
  * Time when the message or event was sent. Formatted in ISO 8601 (e.g. `yyyy-MM-ddThh:mm:ss.SSSZ` or ` 2019-11-08T02:41:28.172Z`)
  * Type: `String`
* `contentType`
  * The type of message
  * Type: `String` (See [ContentType](#contenttype)
* `serializedContent`
  * The raw JSON format of the received WebSocket message
  * Type: Array of `String: Any`

--------
### Message (extends [TranscriptItem](#transcriptitem))

The Message type of TranscriptItem is reserved for all messages sent by bots, contact flow or other participants.  This includes interactive messages, attachments and plain text messages.

```
public class Message: TranscriptItem, MessageProtocol {
    public var participant: String
    public var text: String
    public var messageDirection: MessageDirection?
    public var attachmentId: String?
    public var displayName: String?
    @Published public var metadata: (any MetadataProtocol)?
}
```
* `participant`
  * This is the participant role of the message sender (e.g. `AGENT`)
  * Type: `String`
* `text`
  * This is the text content of the message
  * Type: `String`
* `messageDirection`
  * This is the direction of the message
  * Type: `MessageDirection` (`Outgoing | Incoming | Common`)
* `attachmentId`
  * This is the id of the attachment.  Only defined if this message contains an attachment.
  * Type: `String`
* `displayName`
  * This is the display name of the message
  * Type: `String`
* `metadata`
  * This is the metadata associated with the message.
  * Type: [Metadata](#metadata)
---
### Event (extends [TranscriptItem](#transcriptitem))
The Event type of the TranscriptItem is for events that come through the WebSocket.  See [ContentType](#contenttype) for a list of possible events.

```
public class Event: TranscriptItem, EventProtocol {
    public var participant: String?
    public var text: String?
    public var displayName: String?
    public var eventDirection: MessageDirection?
}
```
* `participant`
  * This is the participant role of the message sender (e.g. `AGENT`)
  * Type: `String?`
* `text`
  * This is the text content of the event
  * Type: `String?`
* `displayName`
  * This is the display name of the event
  * Type: `String`
* `eventDirection`
  * This is the direction of the event
  * Type: `eventDirection` (`Outgoing | Incoming | Common`)

--------
### Metadata (extends [TranscriptItem](#transcriptitem))
The Metadata event is used to receive additional data on a given message such as message receipt status.

```
public class Metadata: TranscriptItem, MetadataProtocol {
    @Published public var status: MessageStatus?
    @Published public var eventDirection: MessageDirection?
```
* `status`
  * This is the receipt status for the event.
  * Type: `MessageStatus` (`'Read' | 'Delivered'`)
* `eventDirection`
  * This is the direction of the metadata event.
  * Type: `eventDirection` (`Outgoing | Incoming | Common`)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.

