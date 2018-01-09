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
    
    var newsArticles: [NewsArticle] {
        return fetchedResultController.fetchedObjects ?? []
    }
    
    var webContentHeights: [CGFloat] = []
    
    
// MARK: - UI Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        self.fetchNewsArticle()
        self.synchronizeNewsArticle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @IBAction func didTriggerRefresh(_ sender: Any) {
        self.synchronizeNewsArticle()
    }
    
    // MARK: Internal convenience
    fileprivate lazy var fetchedResultController : NSFetchedResultsController<NewsArticle> = {
        
        let fetchRequest: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayAt", ascending: false)]
        
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                managedObjectContext: managedObjectContext,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        fetchResultsController.delegate = self
        return fetchResultsController
        
    }()
    
    fileprivate func synchronizeNewsArticle() {
        NewsArticleHelper.fetchFromServer().onSuccess {
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
            webContentHeights = Array(repeating: 0.0, count: newsArticles.count)
        } catch let fetchError as NSError {
            log.error(fetchError)
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Table View Delegate methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsArticles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let item = newsArticles[index]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsArticleCell
        
        cell.title.text = item.title
        
        cell.content.tag = index
        cell.content.delegate = self
        
        cell.content.loadHTMLString(item.content.standardStyledHtml, baseURL: nil)
        cell.heightConstraint.constant = webContentHeights[index]
        
        cell.timeSinceCreated.text = item.timeSinceDisplay
        
        return cell
    }
}

extension NewsListViewController : UIWebViewDelegate {
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        let index = webView.tag
        let height = webView.scrollView.contentSize.height
        if webContentHeights[index] == height {
            return
        }
        
        webContentHeights[index] = height
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
    }
}

extension NewsArticle {
    
    fileprivate var timeSinceDisplay: String {
        return TimeHelper.timeSince(displayAt as Date)
    }
    
}


