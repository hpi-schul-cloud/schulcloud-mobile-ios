//
//  NewsListViewController.swift
//  schulcloud
//
//  Created by Florian Morel on 04.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

class NewsListViewController: UITableViewController, UIWebViewDelegate, NSFetchedResultsControllerDelegate {
    
    var newsArticles: [NewsArticle] {
        return fetchedResultController.fetchedObjects ?? []
    }
    
    // Temporary
    var contentHeight: [CGFloat] = []
    
    
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsCell
        
        cell.title.text = item.title
        
        cell.content.tag = index
        cell.content.delegate = self
        cell.content.scrollView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        cell.content.loadHTMLString(item.content.standardStyledHtml, baseURL: nil)
        cell.heightConstraint.constant = contentHeight[index]

        cell.timeSinceCreated.text = item.timeSinceCreated
        
        return cell
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        let index = webView.tag
        let height = webView.scrollView.contentSize.height
        if contentHeight[index] == height {
            return
        }
        
        contentHeight[index] = height
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
    }
    
    func synchronizeNewsArticle() {
        NewsArticleHelper.fetchFromServer().onSuccess {
            self.fetchNewsArticle()
        }.onFailure(){ error in
            log.error(error.localizedDescription)
        }.onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }
    
    func fetchNewsArticle() {
        //TODO: think of what should happen when fetching fails
        do {
            try self.fetchedResultController.performFetch()
            contentHeight = Array(repeating: 0.0, count: newsArticles.count)
        } catch let fetchError as NSError {
            log.error(fetchError)
        }
        self.tableView.reloadData()
    }
}


extension NewsArticle {
    
    var timeSinceCreated: String {
        
        let component = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: displayAt as Date, to: Date())
        
        if let year = component.year,
            year > 0 {
            
            let year_format = "number_of_year".localized
            let localized_year = String.localizedStringWithFormat(year_format, year)
            
            return String(format: "time.past".localized, localized_year)
        } else if let month = component.month,
            month > 0 {
            
            let month_format = "number_of_month".localized
            let localized_month = String.localizedStringWithFormat(month_format, month)

            return String(format: "time.past".localized, localized_month)
        } else if let day = component.day,
            day > 0 {
            
            let day_format = "number_of_day".localized
            let localized_day = String.localizedStringWithFormat(day_format, day)
            
            return String(format: "time.past".localized, localized_day)
        } else if let hour = component.hour,
            hour > 0 {
            
            let hour_format = "number_of_hour".localized
            let localized_hour = String.localizedStringWithFormat(hour_format, hour)
            
            return String(format: "time.past".localized, localized_hour)
        } else if let minute = component.minute,
            minute > 0 {
            
            let minute_format = "number_of_minute".localized
            let localized_minute = String.localizedStringWithFormat(minute_format, minute)
            
            return String(format: "time.past".localized, localized_minute)
        } else if let second = component.second,
            second > 0 {
            
            let second_format = NSLocalizedString("number_of_second", comment: "")
            let localized_second = String.localizedStringWithFormat(second_format, second)
            
            return String(format: "time.past".localized, localized_second)
        }
        
        return ""
    }
}

// MARK: Convenience
extension String {
    func htmlWrapped(style: String?) -> String {
        return "<html><head>\(style ?? "")</head><body>\(self)</body></html>"
    }
    
    var standardStyledHtml : String {
        return htmlWrapped(style: Constants.textStyleHtml)
    }
    
    var localized : String {
        return NSLocalizedString(self, comment: "")
    }
}

