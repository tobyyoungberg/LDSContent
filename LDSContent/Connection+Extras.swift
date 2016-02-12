//
//  Connection+Extras.swift
//  LDSContent
//
//  Created by Hilton Campbell on 2/11/16.
//  Copyright © 2016 Hilton Campbell. All rights reserved.
//

import Foundation
import SQLite

extension Connection {
    
    func tableExists(tableName: String) -> Bool {
        return scalar("SELECT EXISTS (SELECT * FROM sqlite_master WHERE type='table' AND name=?)", tableName) as? Int ?? 0 > 0
    }
    
}
