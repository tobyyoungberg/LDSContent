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

import UIKit
import LDSContent

class LanguagesViewController: UIViewController {
    
    var catalog: Catalog?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        automaticallyAdjustsScrollViewInsets = false
        
        title = "Languages"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .Plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private static let CellIdentifier = "Cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = true
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: LanguagesViewController.CellIdentifier)
        tableView.estimatedRowHeight = 44
        
        view.addSubview(tableView)
        
        let views = [
            "tableView": tableView,
        ]
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[tableView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[tableView]|", options: [], metrics: nil, views: views))
        
        reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
    var languages = [Language]()
    var uiLanguage: Language?
    
    func reloadData() {
        let tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Failed to create temp directory with error %@", "\(error)")
            return
        }
        
        let destinationURL = tempDirectoryURL.URLByAppendingPathComponent("Catalog.sqlite")
        
        let session = Session()
        
        session.downloadCatalog(destinationURL: destinationURL) { result in
            switch result {
            case .Success:
                guard let path = destinationURL.path else {
                    NSLog("Failed to get temp directory path")
                    break
                }
                
                if let catalog = Catalog(path: path) {
                    dispatch_async(dispatch_get_main_queue()) {
                        if let uiLanguage = catalog.languageWithISO639_3Code("eng") {
                            self.catalog = catalog
                            
                            let languages = catalog.languages()
                            
                            let nameByLanguageID = [Int: String](languages.map { language in
                                return (language.id, catalog.nameForLanguageWithID(language.id, inLanguageWithID: uiLanguage.id))
                            })
                            
                            self.languages = languages.sort { nameByLanguageID[$0.id] < nameByLanguageID[$1.id] }
                            
                            self.uiLanguage = uiLanguage
                            
                            self.tableView.reloadData()
                        }
                    }
                }
            case let .Error(errors: errors):
                NSLog("Failed to download catalog with errors %@", errors)
            }
        }
    }
    
}

// MARK: - UITableViewDataSource

extension LanguagesViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LanguagesViewController.CellIdentifier, forIndexPath: indexPath)
        
        let language = languages[indexPath.row]
        if let catalog = catalog, uiLanguage = uiLanguage {
            cell.textLabel?.text = catalog.nameForLanguageWithID(language.id, inLanguageWithID: uiLanguage.id)
        }
        cell.accessoryType = .DisclosureIndicator
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension LanguagesViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
}
