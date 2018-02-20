//
//  NewsListViewController.swift
//  schulcloud
//
//  Created by Florian Morel on 04.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

class NewsListViewController: UITableViewController,  NSFetchedResultsControllerDelegate {
    
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - UI Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        self.fetchNewsArticle()
        self.synchronizeNewsArticle()
    }

    @IBAction func didTriggerRefresh(_ sender: Any) {
        self.synchronizeNewsArticle()
    }
    
    // MARK: Internal convenience
    fileprivate lazy var fetchedResultController : NSFetchedResultsController<NewsArticle> = {
        let fetchRequest: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayAt", ascending: false)]
        
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                managedObjectContext: CoreDataHelper.persistentContainer.viewContext,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        fetchResultsController.delegate = self
        return fetchResultsController
    }()
    
    fileprivate func synchronizeNewsArticle() {
        NewsArticleHelper.syncNewsArticles().onSuccess { _ in
            self.fetchNewsArticle()
        }.onFailure(){ error in
            log.error(error.localizedDescription)
        }.onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }
    
    fileprivate func fetchNewsArticle() {
        do {
            try self.fetchedResultController.performFetch()
        } catch let fetchError as NSError {
            log.error(fetchError)
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Table View Delegate methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.fetchedResultController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsArticleCell
        
        cell.title.text = item.title
        cell.timeSinceCreated.text = NewsListViewController.displayDateFormatter.string(from: item.displayAt as Date)
        cell.content.attributedText = item.content.convertedHTML
        cell.content.translatesAutoresizingMaskIntoConstraints = true
        cell.content.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        cell.content.sizeToFit()

        return cell
    }
}
