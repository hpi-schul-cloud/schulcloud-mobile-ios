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

        self.tableView.register(UINib(resource: R.nib.homeworkHeaderView),
                                forHeaderFooterViewReuseIdentifier: R.nib.homeworkHeaderView.name)
        self.coreDataTableViewDataSource = CoreDataTableViewDataSource(self.tableView,
                                                                       fetchedResultsController: self.fetchedResultsController,
                                                                       cellReuseIdentifier: R.reuseIdentifier.courseTask.identifier,
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

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionInfo = self.fetchedResultsController.sections![section]
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: R.nib.homeworkHeaderView.name) as? HomeworkHeaderView else {
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

        self.performSegue(withIdentifier: R.segue.homeworkListCourseSortedViewController.taskDetail,
                          sender: self.fetchedResultsController.object(at: indexPath))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let info = R.segue.homeworkListCourseSortedViewController.taskDetail(segue: segue) else {
            super.prepare(for: segue, sender: sender)
            return
        }

        info.destination.homework = sender as? Homework
    }
}

extension HomeworkListCourseSortedViewController: CoreDataTableViewDataSourceDelegate {
    func configure(_ cell: HomeworkByCourseCell, for object: Homework) {
        cell.configure(for: object)
    }
}
