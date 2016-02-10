//
// Copyright (c) 2016 Hilton Campbell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import XCTest
import LDSContent

class DownloadCatalogTests: XCTestCase {
    
    func testDownloadLatestCatalog() {
        let tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Failed to create temp directory with error \(error)")
        }
        defer {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(tempDirectoryURL)
            } catch {}
        }
        
        let session = Session()
        
        let destinationURL = tempDirectoryURL.URLByAppendingPathComponent("Catalog.sqlite")
        
        let expectation = expectationWithDescription("Download latest catalog")
        session.downloadCatalog(destinationURL: destinationURL) { result in
            switch result {
            case .Success:
                XCTAssertTrue(destinationURL.checkResourceIsReachableAndReturnError(nil))
            case let .Error(errors):
                XCTFail("Failed with errors \(errors)")
            }
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(30, handler: nil)
    }
    
    func testDownloadSpecificCatalog() {
        let tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Failed to create temp directory with error \(error)")
        }
        defer {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(tempDirectoryURL)
            } catch {}
        }
        
        let session = Session()
        
        let destinationURL = tempDirectoryURL.URLByAppendingPathComponent("Catalog.sqlite")
        
        let catalogVersion = 250
        
        let expectation = expectationWithDescription("Download latest catalog")
        session.downloadCatalog(destinationURL: destinationURL, catalogVersion: catalogVersion) { result in
            switch result {
            case .Success:
                XCTAssertTrue(destinationURL.checkResourceIsReachableAndReturnError(nil), "Downloaded catalog does not exist")
                
                let catalog = Catalog(path: destinationURL.path!)!
                XCTAssertEqual(catalog.catalogVersion(), catalogVersion)
            case let .Error(errors):
                XCTFail("Failed with errors \(errors)")
            }
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(30, handler: nil)
    }
    
}
