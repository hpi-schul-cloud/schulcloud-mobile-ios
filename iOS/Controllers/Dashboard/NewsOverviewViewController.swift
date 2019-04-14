//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import UIKit

protocol NewsOverviewViewControllerDelegate: AnyObject {
    func heightDidChange(_ height: CGFloat)
    func showMorePressed()
    func didSelect(news: NewsArticle)
}

final class NewsOverviewViewController: UITableViewController {

    @IBOutlet private weak var noNewsLabel: UILabel!
    @IBOutlet private weak var moreNewsButton: UIButton!

    weak var delegate: NewsOverviewViewControllerDelegate?

    private lazy var fetchedController: NSFetchedResultsController<NewsArticle> = {
        let fetchRequest: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayAt", ascending: false)]

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: CoreDataHelper.viewContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        try? fetchedController.performFetch()
        tableView.reloadData()
        NewsArticleHelper.syncNewsArticles()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.delegate?.heightDidChange(tableView.contentSize.height)

        if let headerView = tableView.tableHeaderView {
            let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if headerView.frame.size.height != size.height {
                headerView.frame.size.height = size.height
                self.tableView.tableHeaderView = headerView
                self.tableView.layoutIfNeeded()
            }
        }

        if let footerView = tableView.tableFooterView {
            let size = footerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if footerView.frame.size.height != size.height {
                footerView.frame.size.height = size.height
                self.tableView.tableFooterView = footerView
                self.tableView.layoutIfNeeded()
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedController.fetchedObjects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let newsArticle = self.fetchedController.object(at: indexPath)
        let newsCell = tableView.dequeueReusableCell(withIdentifier: "NewsCell") as! NewsArticleOverviewCell
        newsCell.configure(for: newsArticle)
        return newsCell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newsArticle = self.fetchedController.object(at: indexPath)
        self.delegate?.didSelect(news: newsArticle)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    @IBAction private func showMorePressed() {
        self.delegate?.showMorePressed()
    }
}

extension NewsOverviewViewController: NSFetchedResultsControllerDelegate {
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let isEmpty = controller.fetchedObjects?.isEmpty ?? true
        self.noNewsLabel.isHidden = !isEmpty
        self.moreNewsButton.isHidden = isEmpty
        self.tableView.reloadData()
    }
}

extension NewsOverviewViewController: ViewHeightDataSource {
    var height: CGFloat {
        return tableView.contentSize.height + 20.0
    }
}

extension NewsOverviewViewController: PermissionInfoDataSource {
    static let requiredPermission = UserPermissions.newsView
}
