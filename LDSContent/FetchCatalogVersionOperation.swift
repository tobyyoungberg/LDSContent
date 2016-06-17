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

class FetchCatalogVersionOperation: Operation {
    
    let session: Session
    
    var catalogVersion: Int?
    
    init(session: Session, completion: (FetchCatalogVersionResult) -> Void) {
        self.session = session
        
        super.init()
        
        addObserver(BlockObserver(finishHandler: { operation, errors in
            if errors.isEmpty, let catalogVersion = self.catalogVersion {
                completion(.Success(catalogVersion: catalogVersion))
            } else {
                completion(.Error(errors: errors))
            }
        }))
    }
    
    override func execute() {
        guard let baseURL = NSURL(string: "https://edge.ldscdn.org/mobile/gospelstudy/beta/") else {
            finishWithError(Error.errorWithCode(.Unknown, failureReason: "Malformed URL"))
            return
        }
        
        let indexURL = baseURL.URLByAppendingPathComponent("v3/index.json")
        let request = NSMutableURLRequest(URL: indexURL)
        
        let task = session.urlSession.dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                self.finishWithError(error)
                return
            }
            
            guard let data = data else {
                self.finishWithError(Error.errorWithCode(.Unknown, failureReason: "Missing response data"))
                return
            }
            
            let jsonObject: AnyObject
            do {
                jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            } catch let error as NSError {
                self.finishWithError(error)
                return
            }
            
            guard let jsonDictionary = jsonObject as? [String: AnyObject], catalogVersion = jsonDictionary["catalogVersion"] as? Int else {
                self.finishWithError(Error.errorWithCode(.Unknown, failureReason: "Unexpected JSON response"))
                return
            }
            
            self.catalogVersion = catalogVersion
            
            self.finish()
        }
        task.resume()
    }
    
}
