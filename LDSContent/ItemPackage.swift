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
import FTS3HTMLTokenizer

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
        
        registerTokenizer(db.handle, UnsafeMutablePointer<Int8>(("HTMLTokenizer" as NSString).UTF8String))
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
    
    class SubitemContentVirtualTable {
        
        static let table = VirtualTable("subitem_content_fts")
        static let id = Expression<Int>("_id")
        static let subitemID = Expression<Int>("subitem_id")
        static let title = Expression<String>("title")
        static let uri = Expression<String>("uri")
        static let contentHTML = Expression<String>("content_html")
        
        static func fromRow(row: [Binding?], iso639_3Code: String, keywordSearch: Bool) -> SearchResult {
            return SearchResult(subitemID: Int(row[2] as! Int64), uri: row[4] as! String, title: row[3] as! String, matchRanges: matchRangesFromOffsets(row[0] as! String, keywordSearch: keywordSearch), iso639_3Code: iso639_3Code, snippet: row[1] as! String)
        }
        
        static func matchRangesFromOffsets(offsets: String, keywordSearch: Bool) -> [NSRange] {
            var matchRanges = [NSRange]()
            
            let scanner = NSScanner(string: offsets)
            while !scanner.atEnd {
                var columnNumber = 0
                if !scanner.scanInteger(&columnNumber) {
                    return []
                }
                
                var termNumber = 0
                if !scanner.scanInteger(&termNumber) {
                    return []
                }
                
                var byteOffset = 0
                if !scanner.scanInteger(&byteOffset) {
                    return []
                }
                
                var byteSize = 0
                if !scanner.scanInteger(&byteSize) {
                    return []
                }
                
                let range = NSMakeRange(byteOffset, byteSize)
                if !keywordSearch && termNumber != 0, let lastRange = matchRanges.popLast() {
                    // Combine into single range for exact phrase matches
                    let combinedRange = NSMakeRange(lastRange.location, (range.location - lastRange.location) + range.length)
                    matchRanges.append(combinedRange)
                } else {
                    // Don't try to combine search tokens on keyword search
                    matchRanges.append(range)
                }
            }
            return matchRanges
        }
        
    }

    public func searchResultsForString(searchString: String) -> [SearchResult] {
        let iso639_3Code = self.iso639_3Code!
        let keywordSearch = (searchString.rangeOfString("^\\\".*\\\"$", options: .RegularExpressionSearch) != nil)
        
        do {
            return try db.prepare("SELECT offsets(subitem_content_fts) AS offsets, snippet(subitem_content_fts, '<em class=\"searchMatch\">', '</em>', '…', -1, 35) AS snippet, subitem_content_fts.subitem_id, subitem.title, subitem.uri FROM subitem_content_fts LEFT JOIN subitem ON subitem._id = subitem_content_fts.subitem_id WHERE subitem_content_fts.content_html MATCH ? ORDER BY subitem_content_fts.subitem_id", searchString).map { row in
                return SubitemContentVirtualTable.fromRow(row, iso639_3Code: iso639_3Code, keywordSearch: keywordSearch)
            }
        } catch {
            return []
        }
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

extension ItemPackage {
    
    class RelatedContentItemTable {
        
        static let table = Table("related_content_item")
        static let id = Expression<Int>("_id")
        static let subitemID = Expression<Int>("subitem_id")
        static let refID = Expression<String>("ref_id")
        static let labelHTML = Expression<String>("label_html")
        static let originID = Expression<String>("origin_id")
        static let contentHTML = Expression<String>("content_html")
        static let wordOffset = Expression<Int>("word_offset")
        static let byteLocation = Expression<Int>("byte_location")
        
        static func fromRow(row: Row) -> RelatedContentItem {
            return RelatedContentItem(id: row[id], subitemID: row[subitemID], refID: row[refID], labelHTML: row[labelHTML], originID: row[originID], contentHTML: row[contentHTML], wordOffset: row[wordOffset], byteLocation: row[byteLocation])
        }
        
    }
    
    public func relatedContentItemsForSubitemWithID(subitemID: Int) -> [RelatedContentItem] {
        do {
            return try db.prepare(RelatedContentItemTable.table.filter(RelatedContentItemTable.subitemID == subitemID).order(RelatedContentItemTable.byteLocation)).map { RelatedContentItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    class RelatedAudioItemTable {
        
        static let table = Table("related_audio_item")
        static let id = Expression<Int>("_id")
        static let subitemID = Expression<Int>("subitem_id")
        static let mediaURL = Expression<String>("media_url")
        static let fileSize = Expression<Int>("file_size")
        static let duration = Expression<Int>("duration")
        
        static func fromRow(row: Row) -> RelatedAudioItem {
            return RelatedAudioItem(id: row[id], subitemID: row[subitemID], mediaURL: NSURL(string: row[mediaURL])!, fileSize: row[fileSize], duration: row[duration])
        }
        
        static func fromNamespacedRow(row: Row) -> RelatedAudioItem {
            return RelatedAudioItem(id: row[RelatedAudioItemTable.table[id]], subitemID: row[RelatedAudioItemTable.table[subitemID]], mediaURL: NSURL(string: row[RelatedAudioItemTable.table[mediaURL]])!, fileSize: row[RelatedAudioItemTable.table[fileSize]], duration: row[RelatedAudioItemTable.table[duration]])
        }
        
    }
    
    public func relatedAudioItemsForSubitemWithID(subitemID: Int) -> [RelatedAudioItem] {
        do {
            return try db.prepare(RelatedAudioItemTable.table.filter(RelatedAudioItemTable.subitemID == subitemID)).map { RelatedAudioItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func hasRelatedAudioItemsForSubitemsPrefixedByURI(uri: String) -> Bool {
        return db.scalar(RelatedAudioItemTable.table.join(SubitemTable.table, on: RelatedAudioItemTable.subitemID == SubitemTable.table[SubitemTable.id]).filter(SubitemTable.uri.like("\(uri.escaped())%", escape: "!")).count) > 0
    }
    
    public func relatedAudioItemsForSubitemsPrefixedByURI(uri: String) -> [RelatedAudioItem] {
        do {
            return try db.prepare(RelatedAudioItemTable.table.join(SubitemTable.table, on: RelatedAudioItemTable.subitemID == SubitemTable.table[SubitemTable.id]).filter(SubitemTable.uri.like("\(uri.escaped())%", escape: "!"))).map { RelatedAudioItemTable.fromNamespacedRow($0) }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    class NavCollectionTable {
        
        static let table = Table("nav_collection")
        static let id = Expression<Int>("_id")
        static let navSectionID = Expression<Int?>("nav_section_id")
        static let position = Expression<Int>("position")
        static let imageRenditions = Expression<String?>("image_renditions")
        static let titleHTML = Expression<String>("title_html")
        static let subtitle = Expression<String?>("subtitle")
        static let uri = Expression<String>("uri")
        
        static func fromRow(row: Row) -> NavCollection {
            return NavCollection(id: row[id], navSectionID: row[navSectionID], position: row[position], imageRenditions: (row[imageRenditions] ?? "").toImageRenditions() ?? [], titleHTML: row[titleHTML], subtitle: row[subtitle], uri: row[uri])
        }
        
    }
    
    public func rootNavCollection() -> NavCollection? {
        return db.pluck(NavCollectionTable.table.filter(NavCollectionTable.navSectionID == nil)).map { NavCollectionTable.fromRow($0) }
    }
    
    public func navCollectionWithID(id: Int) -> NavCollection? {
        return db.pluck(NavCollectionTable.table.filter(NavCollectionTable.id == id)).map { NavCollectionTable.fromRow($0) }
    }
    
    public func navCollectionWithURI(uri: String) -> NavCollection? {
        return db.pluck(NavCollectionTable.table.filter(NavCollectionTable.uri == uri)).map { NavCollectionTable.fromRow($0) }
    }
    
    public func navCollectionsForNavSectionWithID(navSectionID: Int) -> [NavCollection] {
        do {
            return try db.prepare(NavCollectionTable.table.filter(NavCollectionTable.navSectionID == navSectionID).order(NavCollectionTable.position)).map { NavCollectionTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    class NavCollectionIndexEntryTable {
        
        static let table = Table("nav_collection_index_entry")
        static let id = Expression<Int>("_id")
        static let navCollectionID = Expression<Int>("nav_collection_id")
        static let position = Expression<Int>("position")
        static let title = Expression<String>("title")
        static let refNavCollectionID = Expression<Int?>("ref_nav_collection_id")
        static let refNavItemID = Expression<Int?>("ref_nav_item_id")
        
        static func fromRow(row: Row) -> NavCollectionIndexEntry {
            return NavCollectionIndexEntry(id: row[id], navCollectionID: row[navCollectionID], position: row[position], title: row[title], refNavCollectionID: row[refNavCollectionID], refNavItemID: row[refNavItemID])
        }
        
    }
    
    public func navCollectionIndexEntryWithID(id: Int) -> NavCollectionIndexEntry? {
        return db.pluck(NavCollectionIndexEntryTable.table.filter(NavCollectionIndexEntryTable.id == id)).map { NavCollectionIndexEntryTable.fromRow($0) }
    }
    
    public func navCollectionIndexEntriesForNavCollectionWithID(navCollectionID: Int) -> [NavCollectionIndexEntry] {
        do {
            return try db.prepare(NavCollectionIndexEntryTable.table.filter(NavCollectionIndexEntryTable.navCollectionID == navCollectionID).order(NavCollectionIndexEntryTable.position)).map { NavCollectionIndexEntryTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    class NavSectionTable {
        
        static let table = Table("nav_section")
        static let id = Expression<Int>("_id")
        static let navCollectionID = Expression<Int>("nav_collection_id")
        static let position = Expression<Int>("position")
        static let indentLevel = Expression<Int>("indent_level")
        static let title = Expression<String?>("title")
        
        static func fromRow(row: Row) -> NavSection {
            return NavSection(id: row[id], navCollectionID: row[navCollectionID], position: row[position], indentLevel: row[indentLevel], title: row[title])
        }
        
    }
    
    public func navSectionWithID(id: Int) -> NavSection? {
        return db.pluck(NavSectionTable.table.filter(NavSectionTable.id == id)).map { NavSectionTable.fromRow($0) }
    }
    
    public func navSectionsForNavCollectionWithID(navCollectionID: Int) -> [NavSection] {
        do {
            return try db.prepare(NavSectionTable.table.filter(NavSectionTable.navCollectionID == navCollectionID).order(NavSectionTable.position)).map { NavSectionTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    class NavItemTable {
        
        static let table = Table("nav_item")
        static let id = Expression<Int>("_id")
        static let navSectionID = Expression<Int>("nav_section_id")
        static let position = Expression<Int>("position")
        static let imageRenditions = Expression<String?>("image_renditions")
        static let titleHTML = Expression<String>("title_html")
        static let subtitle = Expression<String?>("subtitle")
        static let preview = Expression<String?>("preview")
        static let uri = Expression<String>("uri")
        static let subitemID = Expression<Int>("subitem_id")
        
        static func fromRow(row: Row) -> NavItem {
            return NavItem(id: row[id], navSectionID: row[navSectionID], position: row[position], imageRenditions: (row[imageRenditions] ?? "").toImageRenditions() ?? [], titleHTML: row[titleHTML], subtitle: row[subtitle], preview: row[preview], uri: row[uri], subitemID: row[subitemID])
        }
        
    }
    
    public func navItemWithURI(uri: String) -> NavItem? {
        return db.pluck(NavItemTable.table.filter(NavItemTable.uri == uri)).map { NavItemTable.fromRow($0) }
    }
    
    public func navItemsForNavSectionWithID(navSectionID: Int) -> [NavItem] {
        do {
            return try db.prepare(NavItemTable.table.filter(NavItemTable.navSectionID == navSectionID).order(NavItemTable.position)).map { NavItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    public func navNodesForNavSectionWithID(navSectionID: Int) -> [NavNode] {
        var navNodes = [NavNode]()
        navNodes += navCollectionsForNavSectionWithID(navSectionID).map { $0 as NavNode }
        navNodes += navItemsForNavSectionWithID(navSectionID).map { $0 as NavNode }
        return navNodes.sort { $0.position < $1.position }
    }
    
}
