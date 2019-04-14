//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import DateToolsSwift
import UIKit

final class HomeworkListDateSortedViewController: UITableViewController {

    var coreDataTableViewDataSource: CoreDataTableViewDataSource<HomeworkListDateSortedViewController>?
    private lazy var fetchedResultsController: NSFetchedResultsController<Homework> = {
        let now = Date()
        let today: NSDate = Date(year: now.year, month: now.month, day: now.day) as NSDate

        let fetchRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@", today)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataHelper.viewContext,
                                                                  sectionNameKeyPath: "dueDateShort",
                                                                  cacheName: nil)

        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "HomeworkHeaderView", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "HomeworkHeaderView")

        self.coreDataTableViewDataSource = CoreDataTableViewDataSource(self.tableView,
                                                                       fetchedResultsController: self.fetchedResultsController,
                                                                       cellReuseIdentifier: "dateTask",
                                                                       delegate: self)
        try? self.fetchedResultsController.performFetch()
        self.updateData()
    }

    @IBAction private func didTriggerRefresh() {
        self.updateData()
    }

    func updateData() {
        HomeworkHelper.syncHomework().onFailure { error in
            log.error("Syncing homework failed", error: error)
        }.onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionInfo = self.fetchedResultsController.sections![section]
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HomeworkHeaderView") as? HomeworkHeaderView else {
            return nil
        }

        let date = Homework.shortDateFormatter.date(from: sectionInfo.name)!
        let title = Homework.dateFormatter.string(from: date)
        view.configure(title: title, withColor: nil)

        return view
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: false)
        }

        self.performSegue(withIdentifier: "taskDetail", sender: self.fetchedResultsController.object(at: indexPath))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "taskDetail"?:
            guard let detailVC = segue.destination as? HomeworkDetailViewController else { return }
            guard let homework = sender as? Homework else { return }
            detailVC.homework = homework
        default:
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension HomeworkListDateSortedViewController: CoreDataTableViewDataSourceDelegate {
    func configure(_ cell: HomeworkByDateCell, for object: Homework) {
        cell.configure(for: object)
    }
}
