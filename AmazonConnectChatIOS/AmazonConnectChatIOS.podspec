Pod::Spec.new do |spec|
  spec.name          = 'AmazonConnectChatIOS'
  spec.version       = '1.0.1-beta'
  spec.license       = { :type => 'Apache License, Version 2.0', :file => "LICENSE" }
  spec.homepage      = 'https://github.com/amazon-connect/amazon-connect-chat-ios'
  spec.authors       = { 'Michael Liao' => 'mikeliao@amazon.com', 'Rajat Mittal' => 'rajatttt@amazon.com' }
  spec.summary       = 'Amazon Connect Chat SDK for iOS.'
  spec.source        = { :git => 'https://github.com/amazon-connect/amazon-connect-chat-ios.git', :tag => spec.version.to_s }
  spec.description  = <<-DESC
    AmazonConnectChatIOS SDK allows you to integrate Amazon Connect chat functionality in your iOS app.
    DESC
  spec.platform      = :ios, '15.0'
  spec.swift_version = "5.0"

  # Adjust the path to the XCFramework if it's located in a subdirectory
  # spec.vendored_frameworks = 'AmazonConnectChatIOS.xcframework'

  # Specify source files if needed
  spec.source_files = 'Sources/Core/**/*.{h,m,swift}'

  # Specify dependencies, if any
  spec.dependency 'AWSConnectParticipant'

  # Optionally specify resources if your framework includes any
  # spec.resource_bundles = {
  #   'AmazonConnectChatIOS' => ['AmazonConnectChatIOS/Resources/*.xcassets']
  # }
end
