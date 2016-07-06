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

enum DownloadCatalogOperationError: ErrorType {
    case MissingCatalogVersionError(String)
}

class DownloadCatalogOperation: Operation, AutomaticInjectionOperationType {
    var requirement: Int? // Catalog version injected from FetchCatalogVersionOperation
    var result: DownloadCatalogResult? // When used in group operations it's easier to get individual results after all operations have finished
    
    let session: Session
    let progress: (amount: Float) -> Void
    let tempDirectoryURL: NSURL
    let catalogName: String
    let baseURL: NSURL
    
    init(session: Session, catalogName: String, baseURL: NSURL, progress: (amount: Float) -> Void, completion: (DownloadCatalogResult) -> Void) {
        self.session = session
        self.catalogName = catalogName
        self.baseURL = baseURL
        self.progress = progress
        self.tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        
        super.init()
        
        addObserver(BlockObserver(didFinish: { operation, errors in
            if errors.isEmpty, let version = self.requirement {
                let result = DownloadCatalogResult.Success(version: version, location: self.tempDirectoryURL.URLByAppendingPathComponent("Catalog.sqlite"))
                self.result = result
                completion(result)
            } else {
                let result = DownloadCatalogResult.Error(errors: errors)
                self.result = result
                completion(result)
            }
        }))
    }
    
    override func execute() {
        guard let catalogVersion = requirement else {
            finish(DownloadCatalogOperationError.MissingCatalogVersionError("Catalog version was not injected properly and is nil."))
            return
        }
        
        downloadCatalog(baseURL: baseURL, catalogVersion: catalogVersion, progress: progress) { result in
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
    
    func downloadCatalog(baseURL baseURL: NSURL, catalogVersion: Int, progress: (amount: Float) -> Void, completion: (DownloadResult) -> Void) {
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
