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

public struct NavCollection: NavNode, Equatable {
    
    public var id: Int
    public var navSectionID: Int?
    public var position: Int
    public var imageRenditions: [ImageRendition]
    public var titleHTML: String
    public var subtitle: String?
    public var uri: String
    
    public init(id: Int, navSectionID: Int?, position: Int, imageRenditions: [ImageRendition], titleHTML: String, subtitle: String?, uri: String) {
        self.id = id
        self.navSectionID = navSectionID
        self.position = position
        self.imageRenditions = imageRenditions
        self.titleHTML = titleHTML
        self.subtitle = subtitle
        self.uri = uri
    }
    
}

public func == (lhs: NavCollection, rhs: NavCollection) -> Bool {
    return lhs.id == rhs.id &&
        lhs.navSectionID == rhs.navSectionID &&
        lhs.position == rhs.position &&
        lhs.imageRenditions == rhs.imageRenditions &&
        lhs.titleHTML == rhs.titleHTML &&
        lhs.subtitle == rhs.subtitle &&
        lhs.uri == rhs.uri
}
