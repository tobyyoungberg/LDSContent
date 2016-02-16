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

class MutableItemPacakgeTests: XCTestCase {
    
    var itemPackage: MutableItemPackage!
    
    func testSchemaVersion() {
        itemPackage.schemaVersion = Catalog.SchemaVersion
        XCTAssertEqual(itemPackage.schemaVersion, Catalog.SchemaVersion)
    }
    
    func testItemPackageVersion() {
        itemPackage.itemPackageVersion = 250
        XCTAssertEqual(itemPackage.itemPackageVersion, 250)
    }
    
    func testISO639_3Code() {
        itemPackage.iso639_3Code = "eng"
        XCTAssertEqual(itemPackage.iso639_3Code, "eng")
    }
    
    func testURI() {
        itemPackage.uri = "/scriptures/bofm"
        XCTAssertEqual(itemPackage.uri, "/scriptures/bofm")
    }
    
    func testItemID() {
        itemPackage.itemID = 1
        XCTAssertEqual(itemPackage.itemID, 1)
    }
    
    func testItemExternalID() {
        itemPackage.itemExternalID = "_scriptures_bofm_000"
        XCTAssertEqual(itemPackage.itemExternalID, "_scriptures_bofm_000")
    }
    
    func testVacuum() {
        XCTAssertNoThrow(try itemPackage.vacuum())
    }
    
    override func setUp() {
        super.setUp()
        
        do {
            itemPackage = try MutableItemPackage(iso639_1Code: "en")
        } catch {
            itemPackage = nil
        }
    }
    
}
