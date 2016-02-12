//
//  String+SQL.swift
//  LDSContent
//
//  Created by Hilton Campbell on 2/10/16.
//  Copyright © 2016 Hilton Campbell. All rights reserved.
//

import Foundation

private let escapeRegex = try! NSRegularExpression(pattern: "[!%_]", options: [])

extension String {
    
    func withoutDiacritics() -> String {
        let result = NSMutableString(string: self)
        CFStringTransform(result, nil, kCFStringTransformStripCombiningMarks, false)
        return result as String
    }
    
    func escaped() -> String {
        let result = NSMutableString(string: self)
        escapeRegex.replaceMatchesInString(result, options: [], range: NSMakeRange(0, result.length), withTemplate: "!$0")
        return result as String
    }
    
    init?(imageRenditions: [ImageRendition]) {
        if imageRenditions.isEmpty {
            return nil
        }
        
        var components = [String]()
        for imageRendition in imageRenditions {
            components.append("\(imageRendition.size.width)\(imageRendition.size.height),\(imageRendition.url.absoluteString)")
        }
        self.init(components.joinWithSeparator("\n"))
    }
    
    func toImageRenditions() -> [ImageRendition]? {
        var imageRenditions = [ImageRendition]()
        
        let scanner = NSScanner(string: self)
        scanner.charactersToBeSkipped = nil
        
        while true {
            var width: Int = 0
            if !scanner.scanInteger(&width) || width < 0 {
                return nil
            }
            
            if !scanner.scanString("x", intoString: nil) {
                return nil
            }
            
            var height: Int = 0
            if !scanner.scanInteger(&height) || height < 0 {
                return nil
            }
            
            if !scanner.scanString(",", intoString: nil) {
                return nil
            }
            
            var urlString: NSString?
            if !scanner.scanUpToString("\n", intoString: &urlString) {
                return nil
            }
            
            guard let unwrappedURLString = urlString as? String, url = NSURL(string: unwrappedURLString) else { return nil }
            
            imageRenditions.append(ImageRendition(size: CGSize(width: width, height: height), url: url))
            
            if scanner.atEnd {
                break
            }
            
            if !scanner.scanString("\n", intoString: nil) {
                return nil
            }
        }
        
        return imageRenditions.count > 0 ? imageRenditions : nil
    }
    
}
