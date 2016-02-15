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

import Foundation
import SQLite
import Swiftification

public class ItemPackage {
    
    let db: Connection!
    
    public init(path: String? = nil) throws {
        do {
            db = try Connection(path ?? "")
        } catch {
            db = nil
            throw error
        }
        
        try db.execute("PRAGMA synchronous = OFF")
        try db.execute("PRAGMA journal_mode = OFF")
        try db.execute("PRAGMA temp_store = MEMORY")
    }
    
    public func inTransaction(closure: () throws -> Void) throws {
        let inTransactionKey = "txn:\(unsafeAddressOf(self))"
        if NSThread.currentThread().threadDictionary[inTransactionKey] != nil {
            try closure()
        } else {
            NSThread.currentThread().threadDictionary[inTransactionKey] = true
            defer { NSThread.currentThread().threadDictionary.removeObjectForKey(inTransactionKey) }
            try db.transaction {
                try closure()
            }
        }
    }
    
    public var schemaVersion: Int {
        return self.intForMetadataKey("schemaVersion") ?? 0
    }
    
    public var itemPackageVersion: Int {
        return self.intForMetadataKey("itemPackageVersion") ?? 0
    }
    
    public var iso639_3Code: String? {
        return self.stringForMetadataKey("iso639_3")
    }
    
    public var uri: String? {
        return self.stringForMetadataKey("uri")
    }
    
    public var itemID: Int? {
        return self.intForMetadataKey("item_id")
    }
    
    public var itemExternalID: String? {
        return self.stringForMetadataKey("item_external_id")
    }
    
}

extension ItemPackage {
    
    class MetadataTable {
        
        static let table = Table("metadata")
        static let key = Expression<String>("key")
        static let integerValue = Expression<Int>("value")
        static let stringValue = Expression<String>("value")
        
    }
    
    func intForMetadataKey(key: String) -> Int? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).flatMap { row in
            let string = row[MetadataTable.stringValue]
            return Int(string)
        }
    }
    
    func stringForMetadataKey(key: String) -> String? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).map { row in
            return row[MetadataTable.stringValue]
        }
    }
    
}

extension ItemPackage {
    
    class SubitemContentView {
        
        static let table = View("subitem_content")
        static let id = Expression<Int>("_id")
        static let subitemID = Expression<Int>("subitem_id")
        static let data = Expression<NSData>("content_html")
        
        static func fromRow(row: Row) -> SubitemContent {
            return SubitemContent(id: row[id], subitemID: row[subitemID], data: row[data])
        }
        
    }
    
    public func subitemContentWithSubitemID(subitemID: Int) -> SubitemContent? {
        return db.pluck(SubitemContentView.table.filter(SubitemContentView.subitemID == subitemID)).map { SubitemContentView.fromRow($0) }
    }
    
}

extension ItemPackage {
    
    class SubitemContentRangeTable {
        
        static let table = Table("subitem_content_range")
        static let id = Expression<Int>("_id")
        static let subitemID = Expression<Int>("subitem_id")
        static let paragraphID = Expression<String>("paragraph_id")
        static let startIndex = Expression<Int>("start_index")
        static let endIndex = Expression<Int>("end_index")
        
        static func fromRow(row: Row) -> SubitemContentRange {
            return SubitemContentRange(id: row[id], subitemID: row[subitemID], paragraphID: row[paragraphID], range: rangeFromRow(row))
        }
        
        static func rangeFromRow(row: Row) -> NSRange {
            let startIndex = row[SubitemContentRangeTable.startIndex]
            let endIndex = row[SubitemContentRangeTable.endIndex]
            return NSMakeRange(startIndex, endIndex - startIndex)
        }
        
    }
    
    public func rangeOfParagraphWithID(paragraphID: String, inSubitemWithID subitemID: Int) -> SubitemContentRange? {
        return db.pluck(SubitemContentRangeTable.table.filter(SubitemContentRangeTable.subitemID == subitemID && SubitemContentRangeTable.paragraphID == paragraphID)).map { row in
            return SubitemContentRangeTable.fromRow(row)
        }
    }
    
    public func rangesOfParagraphWithIDs(paragraphIDs: [String], inSubitemWithID subitemID: Int) -> [SubitemContentRange] {
        do {
            return try db.prepare(SubitemContentRangeTable.table.filter(paragraphIDs.contains(SubitemContentRangeTable.paragraphID) && SubitemContentRangeTable.subitemID == subitemID).order(SubitemContentRangeTable.subitemID, SubitemContentRangeTable.startIndex)).map { SubitemContentRangeTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    class SubitemTable {
        
        static let table = Table("subitem")
        static let id = Expression<Int>("_id")
        static let uri = Expression<String>("uri")
        static let docID = Expression<String>("doc_id")
        static let docVersion = Expression<Int>("doc_version")
        static let position = Expression<Int>("position")
        static let titleHTML = Expression<String>("title_html")
        static let title = Expression<String>("title")
        static let webURL = Expression<String>("web_url")
        
        static func fromRow(row: Row) -> Subitem {
            return Subitem(id: row[id], uri: row[uri], docID: row[docID], docVersion: row[docVersion], position: row[position], titleHTML: row[titleHTML], title: row[title], webURL: NSURL(string: row[webURL]))
        }
        
    }
    
    public func subitemWithURI(uri: String) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.uri == uri)).map { SubitemTable.fromRow($0) }
    }
    
    public func subitemWithDocID(docID: String) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.docID == docID)).map { SubitemTable.fromRow($0) }
    }
    
    public func subitemWithID(id: Int) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.id == id)).map { SubitemTable.fromRow($0) }
    }
    
    public func subitemAtPosition(position: Int) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.position == position)).map { SubitemTable.fromRow($0) }
    }
    
    public func subitems() -> [Subitem] {
        do {
            return try db.prepare(SubitemTable.table.order(SubitemTable.position)).map { SubitemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func subitemsWithURIs(uris: [String]) -> [Subitem] {
        do {
            return try db.prepare(SubitemTable.table.filter(uris.contains(SubitemTable.uri)).order(SubitemTable.position)).map { SubitemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func subitemsWithURIPrefixedByURI(uri: String) -> [Subitem] {
        do {
            return try db.prepare(SubitemTable.table.filter(SubitemTable.uri.like("\(uri.escaped())%", escape: "!")).order(SubitemTable.position)).map { SubitemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}
