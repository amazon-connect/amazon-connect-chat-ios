Pod::Spec.new do |spec|
  spec.name          = 'AmazonConnectChatIOS'
  spec.version       = '0.0.4-beta'
  spec.license       = { :type => 'Apache License, Version 2.0', :file => "LICENSE" }
  spec.homepage      = 'https://github.com/amazon-connect/amazon-connect-chat-ios'
  spec.authors       = { 'Michael Liao' => 'mikeliao@amazon.com', 'Rajat Mittal' => 'rajatttt@amazon.com' }
  spec.summary       = 'Amazon Connect Chat SDK for iOS ...'
  spec.source        = { :http => 'https://github.com/amazon-connect/amazon-connect-chat-ios/archive/refs/tags/v0.0.4-beta.zip' }
  spec.platform      = :ios, '15.0'
  spec.source_files  = "Sources/**/*.{swift}"
  spec.dependency 'AWSConnectParticipant'
  spec.swift_version = "5.10"
end
