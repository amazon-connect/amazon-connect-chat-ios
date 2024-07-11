Pod::Spec.new do |spec|
  spec.name          = 'AmazonConnectChatIOS'
  spec.version       = '0.0.12-beta'
  spec.license       = { :type => 'Apache License, Version 2.0', :file => "LICENSE" }
  spec.homepage      = 'https://github.com/amazon-connect/amazon-connect-chat-ios'
  spec.authors       = { 'Michael Liao' => 'mikeliao@amazon.com', 'Rajat Mittal' => 'rajatttt@amazon.com' }
  spec.summary       = 'Amazon Connect Chat SDK for iOS ...'
  spec.source        = { :git => 'https://github.com/amazon-connect/amazon-connect-chat-ios', :tag => 'v0.0.12-beta' }
  spec.platform      = :ios, '15.0'
  spec.source_files  = "Sources/Core/**/*.{swift}"
  spec.dependency 'AWSConnectParticipant'
  spec.swift_version = "5.10"
end
