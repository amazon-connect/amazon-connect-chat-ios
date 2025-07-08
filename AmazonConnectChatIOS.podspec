Pod::Spec.new do |spec|
  spec.name          = 'AmazonConnectChatIOS'
  spec.version       = '2.0.3'
  spec.license       = { :type => 'Apache License, Version 2.0', :file => "LICENSE" }
  spec.homepage      = 'https://github.com/amazon-connect/amazon-connect-chat-ios'
  spec.authors       = { 'Amazon Web Services' => 'amazonwebservices' }
  spec.summary       = 'Amazon Connect Chat SDK for iOS ...'
  spec.source        = { :git => 'https://github.com/amazon-connect/amazon-connect-chat-ios', :tag => 'v2.0.3' }
  spec.platform      = :ios, '15.0'
  spec.source_files  = "Sources/Core/**/*.{swift}"
  spec.dependency 'AWSConnectParticipant'
  spec.swift_version = "5.10"
end
