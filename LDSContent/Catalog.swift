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

public class Catalog {
    
    private let db: Connection!
    
    public init?(path: String? = nil) {
        db = try? Connection(path ?? "")
        if db == nil {
            return nil
        }
        
        do {
            try db.execute("PRAGMA synchronous = OFF")
            try db.execute("PRAGMA journal_mode = OFF")
            try db.execute("PRAGMA temp_store = MEMORY")
        } catch {
            return nil
        }
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
    
}

private class MetadataTable {
    
    static let table = Table("metadata")
    static let key = Expression<String>("key")
    static let integerValue = Expression<Int>("value")
    static let stringValue = Expression<String>("value")
    
}

extension Catalog {
    
    func intForMetadataKey(key: String) -> Int? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.integerValue)).map { $0[MetadataTable.integerValue] }
    }
    
    func stringForMetadataKey(key: String) -> String? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).map { $0[MetadataTable.stringValue] }
    }
    
    public func schemaVersion() -> Int? {
        return self.intForMetadataKey("schemaVersion")
    }
    
    public func catalogVersion() -> Int? {
        return self.intForMetadataKey("catalogVersion")
    }
    
}

private class SourceTable {
    
    static let table = Table("source")
    static let key = Expression<String>("key")
    static let id = Expression<Int>("_id")
    static let name = Expression<String>("name")
    static let type = Expression<SourceType>("type_id")
    
    static func fromRow(row: Row) -> Source {
        return Source(id: row[id], name: row[name], type: row.get(type))
    }
    
}

extension Catalog {
    
    public func sources() -> [Source] {
        do {
            return try db.prepare(SourceTable.table).map { SourceTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func sourceWithID(id: Int) -> Source? {
        return db.pluck(SourceTable.table.filter(SourceTable.id == id)).map { SourceTable.fromRow($0) }
    }
    
    public func sourceWithName(name: String) -> Source? {
        return db.pluck(SourceTable.table.filter(SourceTable.name == name)).map { SourceTable.fromRow($0) }
    }
    
}
