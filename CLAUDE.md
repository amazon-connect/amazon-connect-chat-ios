# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Amazon Connect Chat SDK for iOS - A Swift library that enables native iOS applications to integrate Amazon Connect Chat functionality. The SDK wraps the Amazon Connect Participant Service APIs and abstracts WebSocket management, allowing developers to focus on UI/UX while the SDK handles backend communications.

## Development Commands

### Building the Project
- **Xcode**: Open `AmazonConnectChatIOS.xcodeproj` and build using Xcode (⌘+B)
- **Command Line**: `xcodebuild -project AmazonConnectChatIOS.xcodeproj -scheme AmazonConnectChatIOS build`

### Running Tests
- **Xcode**: Use Test Navigator or ⌘+U to run all tests
- **Command Line**: `xcodebuild -project AmazonConnectChatIOS.xcodeproj -scheme AmazonConnectChatIOSTests test`
- **Using Test Plan**: `xcodebuild -project AmazonConnectChatIOS.xcodeproj -testPlan AmazonConnectChatIOS test`

### Package Management
- **Swift Package Manager**: Uses `Package.swift` for SPM integration
- **CocoaPods**: Uses `AmazonConnectChatIOS.podspec` for CocoaPods distribution

## Architecture Overview

### Core Components

1. **ChatSession** (`Sources/Core/Service/ChatSession.swift`)
   - Main entry point and facade for the SDK
   - Singleton pattern (`ChatSession.shared`)
   - Manages chat lifecycle, configuration, and API orchestration

2. **Models Layer** (`Sources/Core/Models/`)
   - `GlobalConfig`: SDK configuration (region, features, metrics)
   - `ChatDetails`: Connection parameters from StartChatContact API
   - `TranscriptItem`/`Message`/`Event`: Message and event representations
   - `ConnectionDetails`: WebSocket and connection token management

3. **Network Layer** (`Sources/Core/Network/`)
   - `WebSocketManager`: Real-time WebSocket communication
   - `APIClient`: Amazon Connect Participant Service API wrapper
   - `AWSClient`: AWS SDK integration and request handling
   - `MessageReceiptsManager`: Read/delivered receipt handling
   - `MetricsManager`: SDK usage metrics and telemetry

4. **Service Layer** (`Sources/Core/Service/`)
   - `ChatService`: Business logic orchestration
   - Coordinates between network layer and models

5. **Utilities** (`Sources/Core/Utils/`)
   - `SDKLogger`: Configurable logging system
   - `CommonUtils`: Shared utility functions
   - `HttpClient`: Generic HTTP client abstraction

### Key Design Patterns

- **Delegation Pattern**: Event callbacks for chat events, connection state
- **Publisher/Subscriber**: Combine framework for reactive data flows
- **Protocol-Oriented**: Heavy use of protocols for testability and modularity
- **Result Type**: Swift Result<Success, Error> for async operations

### Dependencies

- **AWS SDK for iOS**: `AWSCore` and `AWSConnectParticipant` for backend integration
- **Combine**: Reactive programming for event streams
- **Foundation/UIKit**: Standard iOS frameworks

### Message Flow Architecture

1. **Outbound**: ChatSession → ChatService → APIClient → AWS APIs
2. **Inbound**: WebSocket → WebSocketManager → Event Processing → ChatSession callbacks
3. **Transcript Management**: In-memory transcript with pagination support via nextToken

### Event System

The SDK provides comprehensive event callbacks:
- Connection lifecycle: `onConnectionEstablished`, `onConnectionBroken`
- Message events: `onMessageReceived`, `onTranscriptUpdated`
- Participant events: `onParticipantIdle`, `onTyping`, `onReadReceipt`
- Chat lifecycle: `onChatEnded`, `onChatRehydrated`

### Testing Structure

- Unit tests in `AmazonConnectChatIOSTests/`
- Mock implementations for all major components
- Test coverage configured in `AmazonConnectChatIOS.xctestplan`
- Focus on network layer, service layer, and utilities testing

## Integration Notes

- Minimum iOS 15.0+ support
- Swift 5.10+ required
- Requires backend implementation of StartChatContact API
- WebSocket connection management with automatic reconnection
- Message receipt system with configurable throttling
- Attachment upload/download with temporary file management

## Key Files to Understand

- `Sources/Core/Service/ChatSession.swift` - Main SDK interface
- `Sources/Core/Network/WebSocketManager.swift` - Real-time communication
- `Sources/Core/Models/GlobalConfig.swift` - Configuration system
- `Sources/Core/Utils/SDKLogger.swift` - Logging and debugging