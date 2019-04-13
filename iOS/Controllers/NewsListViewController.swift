//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import UIKit

public class NewsListViewController: UITableViewController {

    private var coreDataTableViewDataSource: CoreDataTableViewDataSource<NewsListViewController>?

    private lazy var fetchedResultController: NSFetchedResultsController<NewsArticle> = {
        let fetchRequest: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayAt", ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataHelper.viewContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    // MARK: - UI Methods
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.coreDataTableViewDataSource = CoreDataTableViewDataSource(self.tableView,
                                                                       fetchedResultsController: self.fetchedResultController,
                                                                       cellReuseIdentifier: "newsCell",
                                                                       delegate: self)

        self.fetchNewsArticle()
        self.synchronizeNewsArticle()
    }

    @IBAction private func didTriggerRefresh(_ sender: Any) {
        self.synchronizeNewsArticle()
    }

    private func synchronizeNewsArticle() {
        NewsArticleHelper.syncNewsArticles().onFailure { error in
            log.error("Failed to sync news article", error: error)
        }.onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }

    private func fetchNewsArticle() {
        do {
            try self.fetchedResultController.performFetch()
        } catch let fetchError as NSError {
            log.error("Failed fetching news articles", error: fetchError)
        }
    }

    @IBAction private func donePressed() {
        self.dismiss(animated: true)
    }
}

extension NewsListViewController: CoreDataTableViewDataSourceDelegate {
    func configure(_ cell: NewsArticleCell, for object: NewsArticle) {
        cell.configure(for: object)
    }
}
