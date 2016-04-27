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
    
    public var id: Int
    public var externalID: String
    public var languageID: Int
    public var sourceID: Int
    public var platform: Platform
    public var uri: String
    public var title: String
    public var itemCoverRenditions: [ImageRendition]
    public var itemCategoryID: Int
    public var version: Int
    public var obsolete: Bool
    
    public init(id: Int, externalID: String, languageID: Int, sourceID: Int, platform: Platform, uri: String, title: String, itemCoverRenditions: [ImageRendition], itemCategoryID: Int, version: Int, obsolete: Bool) {
        self.id = id
        self.externalID = externalID
        self.languageID = languageID
        self.sourceID = sourceID
        self.platform = platform
        self.uri = uri
        self.title = title
        self.itemCoverRenditions = itemCoverRenditions
        self.itemCategoryID = itemCategoryID
        self.version = version
        self.obsolete = obsolete
    }
    
}

public func == (lhs: Item, rhs: Item) -> Bool {
    return lhs.id == rhs.id &&
        lhs.externalID == rhs.externalID &&
        lhs.languageID == rhs.languageID &&
        lhs.sourceID == rhs.sourceID &&
        lhs.platform == rhs.platform &&
        lhs.uri == rhs.uri &&
        lhs.title == rhs.title &&
        lhs.itemCoverRenditions == rhs.itemCoverRenditions &&
        lhs.itemCategoryID == rhs.itemCategoryID &&
        lhs.version == rhs.version &&
        lhs.obsolete == rhs.obsolete
}
