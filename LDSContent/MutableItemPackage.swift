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

public class MutableItemPackage: ItemPackage {
    
    public init(path: String? = nil, iso639_1Code: String) throws {
        try super.init(path: path)
        
        try createDatabaseTables(iso639_1Code: iso639_1Code)
    }
    
    private func createDatabaseTables(iso639_1Code iso639_1Code: String) throws {
        try db.transaction {
            if !self.db.tableExists("metadata") {
                if let sqlPath = NSBundle(forClass: self.dynamicType).pathForResource("ItemPackage", ofType: "sql") {
                    let sql = String(format: try String(contentsOfFile: sqlPath, encoding: NSUTF8StringEncoding), iso639_1Code)
                    try self.db.execute(sql)
                } else {
                    throw Error.errorWithCode(.Unknown, failureReason: "Unable to locate SQL for item package.")
                }
            }
        }
    }
    
    public override var schemaVersion: Int {
        get {
            return super.schemaVersion
        }
        set {
            setInt(newValue, forMetadataKey: "schemaVersion")
        }
    }
    
    public override var itemPackageVersion: Int {
        get {
            return super.itemPackageVersion
        }
        set {
            setInt(newValue, forMetadataKey: "itemPackageVersion")
        }
    }
    
    public override var iso639_3Code: String? {
        get {
            return super.iso639_3Code
        }
        set {
            setString(newValue, forMetadataKey: "iso639_3")
        }
    }
    
    public override var uri: String? {
        get {
            return super.uri
        }
        set {
            setString(newValue, forMetadataKey: "uri")
        }
    }
    
    public override var itemID: Int? {
        get {
            return super.itemID
        }
        set {
            setInt(newValue, forMetadataKey: "item_id")
        }
    }
    
    public override var itemExternalID: String? {
        get {
            return super.itemExternalID
        }
        set {
            setString(newValue, forMetadataKey: "item_external_id")
        }
    }
    
    public func vacuum() throws {
        try db.execute("VACUUM")
    }
    
}

extension MutableItemPackage {
    
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
