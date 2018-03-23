//
//  DashboardNewsOverviewViewController.swift
//  schulcloud
//
//  Created by Florian Morel on 21.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData
protocol DashboardNewsOverviewViewControllerDelegate: class {
    func heightDidChange(_ height: CGFloat)
    func showMorePressed()
    func didSelect(news: NewsArticle)
}

final class DashboardNewsOverviewViewControllerCell : UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var displayAt: UILabel!
    @IBOutlet var content: UITextView!
}

final class DashboardNewsOverviewViewController : UITableViewController {

    weak var delegate : DashboardNewsOverviewViewControllerDelegate? = nil

    fileprivate lazy var fetchedController : NSFetchedResultsController<NewsArticle> = {
        let fetchRequest : NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
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
        let cell : UITableViewCell

        if self.fetchedController.fetchedObjects?.count == 0 {
            let emptyCell = tableView.dequeueReusableCell(withIdentifier: "EmptyNewsCell")
            emptyCell?.textLabel?.text = "You have no news item"
            cell = emptyCell!
        } else {
            let newsArticle = self.fetchedController.object(at: indexPath)
            let newsCell = tableView.dequeueReusableCell(withIdentifier: "NewsCell") as! DashboardNewsOverviewViewControllerCell
            newsCell.title.text = newsArticle.title
            newsCell.displayAt.text = NewsArticle.displayDateFormatter.string(for: newsArticle.displayAt)
            newsCell.content.attributedText = newsArticle.content.convertedHTML
            cell = newsCell
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let fetchedObject = fetchedController.fetchedObjects,
                  fetchedObject.count > 0 else { return }
        defer { tableView.deselectRow(at: indexPath, animated: false) }
        let newsArticle = fetchedObject[indexPath.row];
        self.delegate?.didSelect(news: newsArticle)
    }

    @IBAction func showMorePressed() {
        self.delegate?.showMorePressed()
    }
}

extension DashboardNewsOverviewViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

extension DashboardNewsOverviewViewController : ViewControllerHeightDataSource {
    var height : CGFloat {
        return tableView.contentSize.height
    }
}
