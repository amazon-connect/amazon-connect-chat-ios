Pod::Spec.new do |spec|
  spec.name          = 'AmazonConnectChatSDK'
  spec.version       = '1.0.0'
  spec.license       = { :type => 'Apache License, Version 2.0', :file => "LICENSE" }
  spec.homepage      = 'https://github.com/amazon-connect/amazon-connect-chat-ios'
  spec.authors       = { 'Michael Liao' => 'mikeliao@amazon.com', 'Rajat Mittal' => 'rajatttt@amazon.com' }
  spec.summary       = 'Amazon Connect Chat SDK for iOS ...'
  spec.source        = { :git => 'https://github.com/amazon-connect/amazon-connect-chat-ios.git', :tag => 'v1.0.0' }
  spec.platform      = :ios, '13.0'
  spec.source_files  = "Sources/**/*.{swift}"
  spec.dependency 'AWSConnectParticipant'
  spec.swift_version = "5.0"
end
