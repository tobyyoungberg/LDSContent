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
import Operations
import SSZipArchive

class DownloadCatalogOperation: Operation {
    let session: Session
    let catalogVersion: Int
    let progress: (amount: Float) -> Void
    let tempDirectoryURL: NSURL
    
    init(session: Session, catalogVersion: Int, progress: (amount: Float) -> Void, completion: (DownloadCatalogResult) -> Void) {
        self.session = session
        self.catalogVersion = catalogVersion
        self.progress = progress
        self.tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        
        super.init()
        
        addObserver(BlockObserver(didFinish: { operation, errors in
            if errors.isEmpty {
                completion(.Success(location: self.tempDirectoryURL.URLByAppendingPathComponent("Catalog.sqlite")))
            } else {
                completion(.Error(errors: errors))
            }
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(self.tempDirectoryURL)
            } catch {}
        }))
    }
    
    override func execute() {
        downloadCatalog(catalogVersion: catalogVersion, progress: progress) { result in
            switch result {
            case let .Success(location):
                self.extractCatalog(location: location) { result in
                    switch result {
                    case .Success:
                        self.finish()
                    case let .Error(error):
                        self.finish(error)
                    }
                }
            case let .Error(error):
                self.finish(error)
            }
        }
    }
    
    enum DownloadResult {
        case Success(location: NSURL)
        case Error(error: NSError)
    }
    
    func downloadCatalog(catalogVersion catalogVersion: Int, progress: (amount: Float) -> Void, completion: (DownloadResult) -> Void) {
        guard let baseURL = NSURL(string: "https://edge.ldscdn.org/mobile/gospelstudy/beta/") else {
            completion(.Error(error: Error.errorWithCode(.Unknown, failureReason: "Malformed URL")))
            return
        }
        
        let compressedCatalogURL = baseURL.URLByAppendingPathComponent("v3/catalogs/\(catalogVersion).zip")
        let request = NSMutableURLRequest(URL: compressedCatalogURL)
        let task = session.urlSession.downloadTaskWithRequest(request)
        session.registerCallbacks(progress: progress, completion: { result in
            self.session.deregisterCallbacksForTaskIdentifier(task.taskIdentifier)
            
            switch result {
            case let .Error(error: error):
                completion(.Error(error: error))
            case let .Success(location: location):
                completion(.Success(location: location))
            }
        }, forTaskIdentifier: task.taskIdentifier)
        task.resume()
    }
    
    enum ExtractCatalogResult {
        case Success
        case Error(error: NSError)
    }
    
    func extractCatalog(location location: NSURL, completion: (ExtractCatalogResult) -> Void) {
        guard let sourcePath = location.path else {
            completion(.Error(error: Error.errorWithCode(.Unknown, failureReason: "Failed to get compressed catalog path")))
            return
        }
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            completion(.Error(error: error))
            return
        }
        
        guard let destinationPath = tempDirectoryURL.path else {
            completion(.Error(error: Error.errorWithCode(.Unknown, failureReason: "Failed to get temp directory path")))
            return
        }
            
        guard SSZipArchive.unzipFileAtPath(sourcePath, toDestination: destinationPath) else {
            completion(.Error(error: Error.errorWithCode(.Unknown, failureReason: "Failed to decompress catalog")))
            return
        }
        
        let uncompressedCatalogURL = tempDirectoryURL.URLByAppendingPathComponent("Catalog.sqlite")
        
        var error: NSError?
        if !uncompressedCatalogURL.checkResourceIsReachableAndReturnError(&error), let error = error {
            completion(.Error(error: error))
            return
        }
        
        completion(.Success)
    }
    
}
