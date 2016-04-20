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
import PSOperations

class Session: NSObject {
    
    lazy var urlSession: NSURLSession = {
        return NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: self, delegateQueue: nil)
    }()
    
    let operationQueue = OperationQueue()
    
    func fetchCatalogVersion(completion completion: (FetchCatalogVersionResult) -> Void) {
        let operation = FetchCatalogVersionOperation(session: self, completion: completion)
        operationQueue.addOperation(operation)
    }
    
    func downloadCatalog(catalogVersion catalogVersion: Int, completion: (DownloadCatalogResult) -> Void) {
        let operation = DownloadCatalogOperation(session: self, catalogVersion: catalogVersion, completion: completion)
        operationQueue.addOperation(operation)
    }
    
    func downloadItemPackage(externalID externalID: String, version: Int, completion: (DownloadItemPackageResult) -> Void) {
        let operation = DownloadItemPackageOperation(session: self, externalID: externalID, version: version, completion: completion)
        operationQueue.addOperation(operation)
    }
    
}

extension Session: NSURLSessionDelegate {
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(.UseCredential, challenge.protectionSpace.serverTrust.flatMap { NSURLCredential(forTrust: $0) })
    }
    
}
