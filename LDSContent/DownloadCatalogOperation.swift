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
import SSZipArchive

class DownloadCatalogOperation: Operation {
    
    let session: Session
    let destinationURL: NSURL
    
    var catalogVersion: Int?
    
    init(session: Session, destinationURL: NSURL, catalogVersion: Int?, completion: (DownloadCatalogResult) -> Void) {
        self.session = session
        self.destinationURL = destinationURL
        self.catalogVersion = catalogVersion
        
        super.init()
        
        addCondition(CatalogVersionCondition(session: session, catalogVersion: catalogVersion, completion: { condition in
            self.catalogVersion = condition.catalogVersion
        }))
        addObserver(BlockObserver(startHandler: nil, produceHandler: nil, finishHandler: { operation, errors in
            if errors.isEmpty {
                completion(.Success)
            } else {
                completion(.Error(errors: errors))
            }
        }))
    }
    
    override func execute() {
        guard let catalogVersion = catalogVersion else {
            finishWithError(Error.errorWithCode(.Unknown, failureReason: "Unspecified catalog version"))
            return
        }
        
        downloadCatalog(catalogVersion: catalogVersion) { result in
            switch result {
            case let .Success(location):
                self.extractCatalog(location: location) { result in
                    switch result {
                    case .Success:
                        self.finish()
                    case let .Error(error):
                        self.finishWithError(error)
                    }
                }
            case let .Error(error):
                self.finishWithError(error)
            }
        }
    }
    
    enum DownloadResult {
        case Success(location: NSURL)
        case Error(error: NSError)
    }
    
    func downloadCatalog(catalogVersion catalogVersion: Int, completion: (DownloadResult) -> Void) {
        guard let baseURL = NSURL(string: "https://edge.ldscdn.org/mobile/GospelStudy/beta/") else {
            completion(.Error(error: Error.errorWithCode(.Unknown, failureReason: "Malformed URL")))
            return
        }
        
        let compressedCatalogURL = baseURL.URLByAppendingPathComponent("v3/catalogs/\(catalogVersion).zip")
        let request = NSMutableURLRequest(URL: compressedCatalogURL)
        
        let task = session.urlSession.downloadTaskWithRequest(request) { location, response, error in
            if let error = error {
                completion(.Error(error: error))
                return
            }
            
            guard let location = location else {
                completion(.Error(error: Error.errorWithCode(.Unknown, failureReason: "Missing location")))
                return
            }
            
            completion(.Success(location: location))
        }
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
        
        let tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            completion(.Error(error: error))
            return
        }
        defer {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(tempDirectoryURL)
            } catch {}
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
        
        do {
            try NSFileManager.defaultManager().copyItemAtURL(uncompressedCatalogURL, toURL: destinationURL)
        } catch let error as NSError {
            completion(.Error(error: error))
            return
        }
        
        completion(.Success)
    }
    
}