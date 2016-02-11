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
import Swiftification

class LibraryCollectionViewController: UIViewController {
    
    let catalog: Catalog
    let libraryCollection: LibraryCollection
    
    init(catalog: Catalog, libraryCollection: LibraryCollection) {
        self.catalog = catalog
        self.libraryCollection = libraryCollection
        
        super.init(nibName: nil, bundle: nil)
        
        automaticallyAdjustsScrollViewInsets = false
        
        title = libraryCollection.title
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
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: LibraryCollectionViewController.CellIdentifier)
        tableView.estimatedRowHeight = 44
        
        view.addSubview(tableView)
        
        let views = [
            "tableView": tableView,
        ]
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[tableView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[tableView]|", options: [], metrics: nil, views: views))
        
        reloadData()
        tableView.reloadData()
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
    
    var sections = [(librarySection: LibrarySection, libraryNodes: [LibraryNode])]()
    
    func reloadData() {
        let librarySections = catalog.librarySectionsForLibraryCollectionWithID(libraryCollection.id)
        sections = librarySections.map { librarySection in
            return (librarySection: librarySection, libraryNodes: catalog.libraryNodesForLibrarySectionWithID(librarySection.id))
        }
    }
    
}

// MARK: - UITableViewDataSource

extension LibraryCollectionViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].libraryNodes.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].librarySection.title
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LibraryCollectionViewController.CellIdentifier, forIndexPath: indexPath)
        
        let libraryNode = sections[indexPath.section].libraryNodes[indexPath.row]
        cell.textLabel?.text = libraryNode.title
        
        if libraryNode is LibraryCollection {
            cell.accessoryType = .DisclosureIndicator
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension LibraryCollectionViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let libraryNode = sections[indexPath.section].libraryNodes[indexPath.row]
        if let libraryCollection = libraryNode as? LibraryCollection {
            let viewController = LibraryCollectionViewController(catalog: catalog, libraryCollection: libraryCollection)
            
            navigationController?.pushViewController(viewController, animated: true)
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
}
