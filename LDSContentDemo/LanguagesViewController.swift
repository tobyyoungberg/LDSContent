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
    
    let contentController: ContentController
    
    init(contentController: ContentController) {
        self.contentController = contentController
        
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
        
        contentController.catalogUpdateObservers.add(self, operationQueue: .mainQueue(), self.dynamicType.catalogDidUpdate)
        catalog = contentController.catalog
        reloadData()
    }
    
    var catalog: Catalog?
    var uiLanguage: Language?
    var languages = [Language]()
    
    func reloadData() {
        guard let catalog = catalog, uiLanguage = catalog.languageWithISO639_3Code("eng") else { return }
        
        let languages = catalog.languages()
        
        let nameByLanguageID = [Int64: String](languages.map { language in
            return (language.id, catalog.nameForLanguageWithID(language.id, inLanguageWithID: uiLanguage.id))
        })
        
        self.uiLanguage = uiLanguage
        self.languages = languages.sort { language1, language2 in
            if language1.id == uiLanguage.id {
                return true
            }
            if language2.id == uiLanguage.id {
                return false
            }
            return nameByLanguageID[language1.id] < nameByLanguageID[language2.id]
        }
        
        tableView.reloadData()
    }
    
    func catalogDidUpdate(catalog: Catalog) {
        self.catalog = catalog
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
        let language = languages[indexPath.row]
        if let catalog = catalog, rootLibraryCollection = catalog.libraryCollectionWithID(language.rootLibraryCollectionID) {
            let viewController = LibraryCollectionViewController(contentController: contentController, libraryCollection: rootLibraryCollection)
            
            navigationController?.pushViewController(viewController, animated: true)
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
}
