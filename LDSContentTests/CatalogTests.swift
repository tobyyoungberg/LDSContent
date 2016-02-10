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
@testable import LDSContent

class CatalogTests: XCTestCase {
    
    var catalog: Catalog!
    
    func testSchemaVersion() {
        XCTAssertEqual(catalog.schemaVersion()!, 3)
    }
    
    func testCatalogVersion() {
        XCTAssertGreaterThan(catalog.catalogVersion()!, 0)
    }
    
    func testSource() {
        let defaultSource = Source(id: 1, name: "default", type: .Default)
        
        XCTAssertEqual(catalog.sources(), [defaultSource])
        XCTAssertEqual(catalog.sourceWithID(1), defaultSource)
        XCTAssertEqual(catalog.sourceWithName("default"), defaultSource)
        
        let items = catalog.itemsWithSourceID(defaultSource.id)
        XCTAssertGreaterThan(items.count, 1)
    }
    
    func testItemCategory() {
        let scripturesItemCategory = ItemCategory(id: 1, name: "Scriptures")
        
        XCTAssertEqual(catalog.itemCategoryWithID(1), scripturesItemCategory)
    }
    
    func testItems() {
        let items = catalog.items()
        XCTAssertGreaterThan(items.count, 1000)
        
        let expectedItems = Array(items[0..<20])
        
        let items2 = catalog.itemsWithIDsIn(expectedItems.map { $0.id })
        XCTAssertEqual(items2, expectedItems)
        
        let items3 = catalog.itemsWithExternalIDsIn(expectedItems.map { $0.externalID })
        XCTAssertEqual(items3, expectedItems)
        
        let items4 = catalog.itemsWithURIsIn(["/scriptures/bofm", "/scriptures/dc-testament"], languageID: 1)
        XCTAssertEqual(items4.count, 2)
        
        let expectedItem = items.first!
        
        let item = catalog.itemWithID(expectedItem.id)
        XCTAssertEqual(item, expectedItem)
        
        let item2 = catalog.itemWithExternalID(expectedItem.externalID)
        XCTAssertEqual(item2, expectedItem)
        
        let item3 = catalog.itemWithURI(expectedItem.uri, languageID: expectedItem.languageID)
        XCTAssertEqual(item3, expectedItem)
        
        let item4 = catalog.itemThatContainsURI("/scriptures/bofm/1-ne/1", languageID: 1)
        XCTAssertEqual(item4!.uri, "/scriptures/bofm")
    }
    
    func testItemTitles() {
        let items = catalog.itemsWithTitlesThatContainString("Mormon", languageID: 1, limit: 10)
        XCTAssertTrue(items.contains { $0.title == "Book of Mormon" })
        
        let items2 = catalog.itemsWithTitlesThatContainString("mormon", languageID: 1, limit: 10)
        XCTAssertTrue(items2.contains { $0.title == "Book of Mormon" })
        
        let items3 = catalog.itemsWithTitlesThatContainString("Mormón", languageID: 1, limit: 10)
        XCTAssertTrue(items3.contains { $0.title == "Book of Mormon" })
        
        let items4 = catalog.itemsWithTitlesThatContainString("Mormon", languageID: 3, limit: 10)
        XCTAssertTrue(items4.contains { $0.title == "Libro de Mormón" })
        
        let items5 = catalog.itemsWithTitlesThatContainString("Mormo_", languageID: 1, limit: 10)
        XCTAssertEqual(items5.count, 0)
        
        let items6 = catalog.itemsWithTitlesThatContainString("Mormo%", languageID: 1, limit: 10)
        XCTAssertEqual(items6.count, 0)
        
        let items7 = catalog.itemsWithTitlesThatContainString("!Mormon", languageID: 1, limit: 10)
        XCTAssertEqual(items7.count, 0)
    }
    
    func testLibraryCollections() {
        let libraryCollections = catalog.libraryCollections()
        XCTAssertGreaterThan(libraryCollections.count, 0)
        
        let firstScripturesLibraryCollection = libraryCollections.find { $0.type == .Scriptures }!
        
        let items = catalog.itemsForLibraryCollectionWithID(firstScripturesLibraryCollection.id)
        XCTAssertGreaterThan(items.count, 0)
    }
    
}

extension CatalogTests {
    
    struct Static {
        static var tempDirectoryURL: NSURL!
        static var catalog: Catalog!
    }
    
    override class func tearDown() {
        do {
            try NSFileManager.defaultManager().removeItemAtURL(Static.tempDirectoryURL)
        } catch {}
        
        super.tearDown()
    }
    
    override func setUp() {
        super.setUp()
        
        if Static.catalog == nil {
            Static.tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(Static.tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Failed to create temp directory with error %@", "\(error)")
                return
            }
            
            let session = Session()
            
            let destinationURL = Static.tempDirectoryURL.URLByAppendingPathComponent("Catalog.sqlite")
            
            let semaphore = dispatch_semaphore_create(0)
            session.downloadCatalog(destinationURL: destinationURL) { result in
                switch result {
                case .Success:
                    Static.catalog = Catalog(path: destinationURL.path!)!
                case let .Error(errors):
                    NSLog("Failed with errors %@", "\(errors)")
                }
                dispatch_semaphore_signal(semaphore)
            }
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(30 * NSEC_PER_SEC)))
        }
        
        catalog = Static.catalog
    }

}
