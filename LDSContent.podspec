Pod::Spec.new do |s|
  s.name         = "LDSContent"
  s.version      = "1.1.1"
  s.summary      = "Swift client library for LDS content."
  s.author       = 'Hilton Campbell'
  s.homepage     = "https://github.com/CrossWaterBridge/LDSContent"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.source       = { :git => "https://github.com/CrossWaterBridge/LDSContent.git", :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.11'
  s.source_files = "LDSContent/*.swift"
  s.resources    = "LDSContent/*.{sql,json}"
  s.requires_arc = true
  
  s.dependency 'PSOperations'
  s.dependency 'SQLite.swift', '~> 0.9.2'
  s.dependency 'FTS3HTMLTokenizer', '~> 2.0'
  s.dependency 'Swiftification'
  s.dependency 'SSZipArchive'
end
