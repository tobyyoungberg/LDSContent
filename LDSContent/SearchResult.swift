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

public struct SearchResult: Equatable {

    public var subitemID: Int
    public var uri: String
    public var title: String
    public var matchRanges: [NSRange]
    public var iso639_3Code: String
    public var snippet: String
    
    public init(subitemID: Int, uri: String, title: String, matchRanges: [NSRange], iso639_3Code: String, snippet: String) {
        self.subitemID = subitemID
        self.uri = uri
        self.title = title
        self.matchRanges = matchRanges
        self.iso639_3Code = iso639_3Code
        self.snippet = snippet
    }
    
}

public func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
    return lhs.subitemID == rhs.subitemID &&
        lhs.uri == rhs.uri &&
        lhs.title == rhs.title &&
        lhs.matchRanges == rhs.matchRanges &&
        lhs.iso639_3Code == rhs.iso639_3Code &&
        lhs.snippet == rhs.snippet
}
