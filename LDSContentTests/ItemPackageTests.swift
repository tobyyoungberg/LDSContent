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

class ItemPackageTests: XCTestCase {
    
    var itemPackage: ItemPackage!
    
    func testSchemaVersion() {
        XCTAssertEqual(itemPackage.schemaVersion, Catalog.SchemaVersion)
    }
    
    func testItemPackageVersion() {
        XCTAssertGreaterThan(itemPackage.itemPackageVersion, 0)
    }
    
    func testISO639_3Code() {
        XCTAssertEqual(itemPackage.iso639_3Code, "eng")
    }
    
    func testURI() {
        XCTAssertEqual(itemPackage.uri, "/scriptures/bofm")
    }
    
    func testItemID() {
        XCTAssertGreaterThan(itemPackage.itemID!, 0)
    }
    
    func testItemExternalID() {
        XCTAssertEqual(itemPackage.itemExternalID, "_scriptures_bofm_000")
    }
    
    func testSubitemContent() {
        let subitemID = 1
        let subitemContent = itemPackage.subitemContentWithSubitemID(subitemID)
        XCTAssertGreaterThan(subitemContent!.id, 0)
        XCTAssertEqual(subitemContent!.subitemID, subitemID)
        XCTAssertNotNil(subitemContent!.data)
    }
    
    func testSubitemContentRange() {
        let subitemContentRange = itemPackage.rangeOfParagraphWithID("title1", inSubitemWithID: 1)
        XCTAssertGreaterThan(subitemContentRange!.id, 0)
        XCTAssertEqual(subitemContentRange!.subitemID, 1)
        XCTAssertEqual(subitemContentRange!.paragraphID, "title1")
        XCTAssertGreaterThan(subitemContentRange!.range.location, 0)
        XCTAssertGreaterThan(subitemContentRange!.range.length, 0)
        
        let subitemContentRanges = itemPackage.rangesOfParagraphWithIDs(["title1", "subtitle1"], inSubitemWithID: 1)
        XCTAssertEqual(subitemContentRanges.count, 2)
        for subitemContentRange in subitemContentRanges {
            XCTAssertGreaterThan(subitemContentRange.id, 0)
            XCTAssertEqual(subitemContentRange.subitemID, 1)
            XCTAssertGreaterThan(subitemContentRange.range.location, 0)
            XCTAssertGreaterThan(subitemContentRange.range.length, 0)
        }
    }
    
    func testSubitem() {
        let uri = "/scriptures/bofm/1-ne/1"
        let subitem = itemPackage.subitemWithURI(uri)!
        XCTAssertGreaterThan(subitem.id, 0)
        XCTAssertEqual(subitem.uri, uri)
        
        let subitem2 = itemPackage.subitemWithDocID(subitem.docID)!
        XCTAssertEqual(subitem2, subitem)
        
        let subitem3 = itemPackage.subitemWithID(subitem.id)!
        XCTAssertEqual(subitem3, subitem)
        
        let subitem4 = itemPackage.subitemAtPosition(subitem.position)!
        XCTAssertEqual(subitem4, subitem)
        
        let subitems = itemPackage.subitems()
        XCTAssertGreaterThan(subitems.count, 10)
        
        let subitems2 = itemPackage.subitemsWithURIs(["/scriptures/bofm/alma/5", "/scriptures/bofm/enos/1"])
        XCTAssertEqual(subitems2.count, 2)
        
        let subitems3 = itemPackage.subitemsWithURIPrefixedByURI("/scriptures/bofm")
        XCTAssertEqual(subitems3, subitems)
    }
    
}

extension ItemPackageTests {
    
    struct Static {
        static var tempDirectoryURL: NSURL!
        static var itemPackage: ItemPackage!
    }
    
    override class func tearDown() {
        do {
            try NSFileManager.defaultManager().removeItemAtURL(Static.tempDirectoryURL)
        } catch {}
        
        super.tearDown()
    }
    
    override func setUp() {
        super.setUp()
        
        if Static.itemPackage == nil {
            Static.tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(Static.tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Failed to create temp directory with error %@", "\(error)")
                return
            }
            
            let session = Session()
            
            let destinationURL = Static.tempDirectoryURL.URLByAppendingPathComponent("Catalog.sqlite")
            
            var catalog: Catalog?
            let semaphore = dispatch_semaphore_create(0)
            session.downloadCatalog(destinationURL: destinationURL) { result in
                switch result {
                case .Success:
                    do {
                        catalog = try Catalog(path: destinationURL.path!)
                    } catch {
                        NSLog("Failed to connect to catalog: %@", "\(error)")
                    }
                case let .Error(errors):
                    NSLog("Failed with errors %@", "\(errors)")
                }
                dispatch_semaphore_signal(semaphore)
            }
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(30 * NSEC_PER_SEC)))
            
            if let catalog = catalog, language = catalog.languageWithISO639_3Code("eng"), item = catalog.itemWithURI("/scriptures/bofm", languageID: language.id) {
                let destinationURL = Static.tempDirectoryURL.URLByAppendingPathComponent("\(item.externalID)-\(item.latestVersion)")
                
                let semaphore = dispatch_semaphore_create(0)
                session.downloadItemPackage(destinationURL: destinationURL, externalID: item.externalID, version: item.latestVersion) { result in
                    switch result {
                    case .Success:
                        do {
                            Static.itemPackage = try ItemPackage(path: destinationURL.URLByAppendingPathComponent("package.sqlite").path!)
                        } catch {
                            NSLog("Failed to connect to catalog: %@", "\(error)")
                        }
                    case let .Error(errors):
                        NSLog("Failed with errors %@", "\(errors)")
                    }
                    dispatch_semaphore_signal(semaphore)
                }
                dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(30 * NSEC_PER_SEC)))
            }
        }
        
        itemPackage = Static.itemPackage
    }
    
}
