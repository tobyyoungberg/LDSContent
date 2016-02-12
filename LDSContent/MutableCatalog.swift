//
//  MutableCatalog.swift
//  LDSContent
//
//  Created by Hilton Campbell on 2/11/16.
//  Copyright © 2016 Hilton Campbell. All rights reserved.
//

import Foundation
import SQLite

public class MutableCatalog: Catalog {
    
    public override init?(path: String? = nil) {
        super.init(path: path)
        
        if !createDatabaseTables() {
            return nil
        }
    }
    
    private func createDatabaseTables() -> Bool {
        do {
            try db.transaction {
                if !self.db.tableExists("metadata") {
                    if let sqlPath = NSBundle(forClass: self.dynamicType).pathForResource("Catalog", ofType: "sql") {
                        let sql = try String(contentsOfFile: sqlPath, encoding: NSUTF8StringEncoding)
                        try self.db.execute(sql)
                    } else {
                        throw Error.errorWithCode(.Unknown, failureReason: "Failed to load SQL.")
                    }
                }
            }
            
            return true
        } catch {
            return false
        }
    }
    
    public override var schemaVersion: Int? {
        get {
            return super.schemaVersion
        }
        set {
            setInt(newValue, forMetadataKey: "schemaVersion")
        }
    }
    
    public override var catalogVersion: Int? {
        get {
            return super.catalogVersion
        }
        set {
            setInt(newValue, forMetadataKey: "catalogVersion")
        }
    }
    
    public func vacuum() throws {
        try db.execute("VACUUM")
    }
    
}

extension MutableCatalog {
    
    func setInt(integerValue: Int?, forMetadataKey key: String) {
        do {
            if let integerValue = integerValue {
                try db.run(MetadataTable.table.insert(or: .Replace, MetadataTable.key <- key, MetadataTable.integerValue <- integerValue))
            } else {
                try db.run(MetadataTable.table.filter(MetadataTable.key == key).delete())
            }
        } catch {}
    }
    
    func setString(stringValue: String?, forMetadataKey key: String) {
        do {
            if let stringValue = stringValue {
                try db.run(MetadataTable.table.insert(or: .Replace, MetadataTable.key <- key, MetadataTable.stringValue <- stringValue))
            } else {
                try db.run(MetadataTable.table.filter(MetadataTable.key == key).delete())
            }
        } catch {}
    }
    
}

extension MutableCatalog {

    public func addOrUpdateSource(source: Source) throws {
        try db.run(SourceTable.table.insert(or: .Replace,
            SourceTable.id <- source.id,
            SourceTable.name <- source.name,
            SourceTable.typeID <- source.type.rawValue
        ))
    }
    
    public func addOrUpdateItemCategory(itemCategory: ItemCategory) throws {
        try db.run(ItemCategoryTable.table.insert(or: .Replace,
            ItemCategoryTable.id <- itemCategory.id,
            ItemCategoryTable.name <- itemCategory.name
        ))
    }
    
    public func addOrUpdateItem(item: Item) throws {
        try db.run(ItemTable.table.insert(or: .Replace,
            ItemTable.id <- item.id,
            ItemTable.externalID <- item.externalID,
            ItemTable.languageID <- item.languageID,
            ItemTable.sourceID <- item.sourceID,
            ItemTable.platformID <- item.platformID,
            ItemTable.uri <- item.uri,
            ItemTable.title <- item.title,
            ItemTable.itemCoverRenditions <- String(item.itemCoverRenditions),
            ItemTable.itemCategoryID <- item.itemCategoryID,
            ItemTable.latestVersion <- item.latestVersion,
            ItemTable.obsolete <- item.obsolete
        ))
    }
    
    public func addOrUpdateLanguage(language: Language) throws {
        try db.run(LanguageTable.table.insert(or: .Replace,
            LanguageTable.id <- language.id,
            LanguageTable.ldsLanguageCode <- language.ldsLanguageCode,
            LanguageTable.iso639_3Code <- language.iso639_3Code,
            LanguageTable.bcp47Code <- language.bcp47Code,
            LanguageTable.rootLibraryCollectionID <- language.rootLibraryCollectionID,
            LanguageTable.rootLibraryCollectionExternalID <- language.rootLibraryCollectionExternalID
        ))
    }
    
    public func setName(name: String, forLanguageWithID languageID: Int, inLanguageWithID localizationLanguageID: Int) throws {
        try db.run(LanguageNameTable.table.insert(
            LanguageNameTable.languageID <- languageID,
            LanguageNameTable.localizationLanguageID <- localizationLanguageID,
            LanguageNameTable.name <- name
        ))
    }
    
    public func addOrUpdateLibraryCollection(libraryCollection: LibraryCollection) throws {
        try db.run(LibraryCollectionTable.table.insert(or: .Replace,
            LibraryCollectionTable.id <- libraryCollection.id,
            LibraryCollectionTable.externalID <- libraryCollection.externalID,
            LibraryCollectionTable.librarySectionID <- libraryCollection.librarySectionID,
            LibraryCollectionTable.librarySectionExternalID <- libraryCollection.librarySectionExternalID,
            LibraryCollectionTable.position <- libraryCollection.position,
            LibraryCollectionTable.title <- libraryCollection.title,
            LibraryCollectionTable.coverRenditions <- String(libraryCollection.coverRenditions),
            LibraryCollectionTable.typeID <- libraryCollection.type.rawValue
        ))
    }
    
    public func addOrUpdateLibrarySection(librarySection: LibrarySection) throws {
        try db.run(LibrarySectionTable.table.insert(or: .Replace,
            LibrarySectionTable.id <- librarySection.id,
            LibrarySectionTable.externalID <- librarySection.externalID,
            LibrarySectionTable.libraryCollectionID <- librarySection.libraryCollectionID,
            LibrarySectionTable.libraryCollectionExternalID <- librarySection.libraryCollectionExternalID,
            LibrarySectionTable.position <- librarySection.position,
            LibrarySectionTable.title <- librarySection.title,
            LibrarySectionTable.indexTitle <- librarySection.indexTitle
        ))
    }
    
    public func addOrUpdateLibraryItem(libraryItem: LibraryItem) throws {
        try db.run(LibraryItemTable.table.insert(or: .Replace,
            LibraryItemTable.id <- libraryItem.id,
            LibraryItemTable.externalID <- libraryItem.externalID,
            LibraryItemTable.librarySectionID <- libraryItem.librarySectionID,
            LibraryItemTable.librarySectionExternalID <- libraryItem.librarySectionExternalID,
            LibraryItemTable.position <- libraryItem.position,
            LibraryItemTable.title <- libraryItem.title,
            LibraryItemTable.obsolete <- libraryItem.obsolete,
            LibraryItemTable.itemID <- libraryItem.itemID,
            LibraryItemTable.itemExternalID <- libraryItem.itemExternalID
        ))
    }
    
    public func addStopword(stopword: Stopword) throws {
        try db.run(StopwordTable.table.insert(
            StopwordTable.languageID <- stopword.languageID,
            StopwordTable.word <- stopword.word
        ))
    }
    
    public func addSubitemID(subitemID: Int, itemID: Int, docID: String, docVersion: Int) throws {
        try db.run(SubitemMetadataTable.table.insert(
            SubitemMetadataTable.subitemID <- subitemID,
            SubitemMetadataTable.itemID <- itemID,
            SubitemMetadataTable.docID <- docID,
            SubitemMetadataTable.docVersion <- docVersion
        ))
    }
    
}
