//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import DateToolsSwift
import UIKit

final class HomeworkListCourseSortedViewController: UITableViewController {

    var coreDataTableViewDataSource: CoreDataTableViewDataSource<HomeworkListCourseSortedViewController>?

    private lazy var fetchedResultsController: NSFetchedResultsController<Homework> = {
        let now = Date()
        let today: NSDate = Date(year: now.year, month: now.month, day: now.day) as NSDate

        let fetchRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
        fetchRequest.sortDescriptors = ["course.name", "dueDate"].map { return NSSortDescriptor(key: $0, ascending: true) }
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@", today)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataHelper.viewContext,
                                                                  sectionNameKeyPath: "course.name",
                                                                  cacheName: nil)

        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "HomeworkHeaderView", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "HomeworkHeaderView")

        self.coreDataTableViewDataSource = CoreDataTableViewDataSource(self.tableView,
                                                                       fetchedResultsController: self.fetchedResultsController,
                                                                       cellReuseIdentifier: "courseTask",
                                                                       delegate: self)
        try? self.fetchedResultsController.performFetch()
        self.updateData()
    }

    @IBAction func didTriggerRefresh() {
        self.updateData()
    }

    func updateData() {
        HomeworkHelper.syncHomework().onFailure { error in
            log.error("%@", error.description)
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

        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", sectionInfo.name)
        guard let course = CoreDataHelper.viewContext.fetchSingle(fetchRequest).value,
            let colorString = course.colorString,
            let courseColor = UIColor(hexString: colorString) else {
                return nil
        }

        view.configure(title: course.name, withColor: courseColor)
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

extension HomeworkListCourseSortedViewController: CoreDataTableViewDataSourceDelegate {
    func configure(_ cell: HomeworkByCourseCell, for object: Homework) {
        cell.configure(for: object)
    }
}
