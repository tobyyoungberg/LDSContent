source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'

use_frameworks!

workspace 'LDSContent'
xcodeproj 'LDSContent.xcodeproj'

target 'LDSContent' do
    pod 'PSOperations'
    pod 'SQLite.swift'
    pod 'FTS3HTMLTokenizer', '~> 2.0', :inhibit_warnings => true
    pod 'Swiftification'
    pod 'SSZipArchive'
end

target 'LDSContentTests' do
    # Required by LDSContent
    pod 'PSOperations'
    pod 'SQLite.swift'
    pod 'FTS3HTMLTokenizer', '~> 2.0', :inhibit_warnings => true
    pod 'Swiftification'
    pod 'SSZipArchive'
end

target 'LDSContentDemo' do
    xcodeproj 'LDSContentDemo.xcodeproj'
    
    pod 'SVProgressHUD'
    
    # Required by LDSContent
    pod 'PSOperations'
    pod 'SQLite.swift'
    pod 'FTS3HTMLTokenizer', '~> 2.0', :inhibit_warnings => true
    pod 'Swiftification'
    pod 'SSZipArchive'
end
