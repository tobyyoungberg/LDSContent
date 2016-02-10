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

public struct Language: Equatable {
    
    public var id: Int
    public var ldsLanguageCode: String
    public var iso639_3Code: String
    public var bcp47Code: String?
    public var rootLibraryCollectionID: Int
    public var rootLibraryCollectionExternalID: String
    
}

public func == (lhs: Language, rhs: Language) -> Bool {
    return lhs.id == rhs.id && lhs.ldsLanguageCode == rhs.ldsLanguageCode && lhs.iso639_3Code == rhs.iso639_3Code && lhs.bcp47Code == rhs.bcp47Code && lhs.rootLibraryCollectionID == rhs.rootLibraryCollectionID && lhs.rootLibraryCollectionExternalID == rhs.rootLibraryCollectionExternalID
}
