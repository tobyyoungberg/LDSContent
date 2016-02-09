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

public struct Item: Equatable {
    
    var id: Int
    var itemExternalID: String
    var languageID: Int
    var sourceID: Int
    var platformID: Int
    var uri: String
    var title: String
    var itemCoverRenditions: [ImageRendition]
    var itemCategoryID: Int
    var latestVersion: Int
    var obsolete: Bool
    
    init(id: Int, itemExternalID: String, languageID: Int, sourceID: Int, platformID: Int, uri: String, title: String, itemCoverRenditions: [ImageRendition], itemCategoryID: Int, latestVersion: Int, obsolete: Bool) {
        self.id = id
        self.itemExternalID = itemExternalID
        self.languageID = languageID
        self.sourceID = sourceID
        self.platformID = platformID
        self.uri = uri
        self.title = title
        self.itemCoverRenditions = itemCoverRenditions
        self.itemCategoryID = itemCategoryID
        self.latestVersion = latestVersion
        self.obsolete = obsolete
    }
    
}

public func == (lhs: Item, rhs: Item) -> Bool {
    return lhs.id == rhs.id &&
        lhs.itemExternalID == rhs.itemExternalID &&
        lhs.languageID == rhs.languageID &&
        lhs.sourceID == rhs.sourceID &&
        lhs.platformID == rhs.platformID &&
        lhs.uri == rhs.uri &&
        lhs.title == rhs.title &&
        lhs.itemCoverRenditions == rhs.itemCoverRenditions &&
        lhs.itemCategoryID == rhs.itemCategoryID &&
        lhs.latestVersion == rhs.latestVersion &&
        lhs.obsolete == rhs.obsolete
}
