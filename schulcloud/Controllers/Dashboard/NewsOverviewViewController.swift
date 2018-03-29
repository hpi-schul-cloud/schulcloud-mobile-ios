//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit
import CoreData

protocol NewsOverviewViewControllerDelegate: class {
    func heightDidChange(_ height: CGFloat)
    func showMorePressed()
    func didSelect(news: NewsArticle)
}

final class NewsOverviewViewController: UITableViewController {

    weak var delegate: NewsOverviewViewControllerDelegate?

    fileprivate lazy var fetchedController: NSFetchedResultsController<NewsArticle> = {
        let fetchRequest: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayAt", ascending: false)]

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataHelper.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        try! fetchedController.performFetch()
        tableView.reloadData()
        NewsArticleHelper.syncNewsArticles()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.delegate?.heightDidChange(tableView.contentSize.height)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let fetchedObjects = self.fetchedController.fetchedObjects else { return 1 }
        return fetchedObjects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell

        if self.fetchedController.fetchedObjects?.count == 0 {
            let emptyCell = tableView.dequeueReusableCell(withIdentifier: "EmptyNewsCell")
            cell = emptyCell!
        } else {
            let newsArticle = self.fetchedController.object(at: indexPath)
            let newsCell = tableView.dequeueReusableCell(withIdentifier: "NewsCell") as! NewsArticleOverviewCell
            newsCell.configure(for: newsArticle)
            cell = newsCell
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let fetchedObject = fetchedController.fetchedObjects,
                  fetchedObject.count > 0 else { return }
        defer { tableView.deselectRow(at: indexPath, animated: false) }
        let newsArticle = fetchedObject[indexPath.row]
        self.delegate?.didSelect(news: newsArticle)
    }

    @IBAction func showMorePressed() {
        self.delegate?.showMorePressed()
    }
}

extension NewsOverviewViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

extension NewsOverviewViewController: ViewControllerHeightDataSource {
    var height: CGFloat {
        return tableView.contentSize.height + 20.0
    }
}
