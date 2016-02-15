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

public struct Subitem: Equatable {
    
    public var id: Int
    public var uri: String
    public var docID: String
    public var docVersion: Int
    public var position: Int
    public var titleHTML: String
    public var title: String
    public var webURL: NSURL?
    
    public init(id: Int, uri: String, docID: String, docVersion: Int, position: Int, titleHTML: String, title: String, webURL: NSURL?) {
        self.id = id
        self.uri = uri
        self.docID = docID
        self.docVersion = docVersion
        self.position = position
        self.titleHTML = titleHTML
        self.title = title
        self.webURL = webURL
    }
    
}

public func == (lhs: Subitem, rhs: Subitem) -> Bool {
    return lhs.id == rhs.id &&
        lhs.uri == rhs.uri &&
        lhs.docID == rhs.docID &&
        lhs.docVersion == rhs.docVersion &&
        lhs.position == rhs.position &&
        lhs.titleHTML == rhs.titleHTML &&
        lhs.title == rhs.title &&
        lhs.webURL == rhs.webURL
}
