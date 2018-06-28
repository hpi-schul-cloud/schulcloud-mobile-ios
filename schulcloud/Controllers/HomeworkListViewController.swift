//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

/// TODO(permissions):
///   teacher only (not needed yet)
///     homeworkEdit? - not sure we want to do that
///     homeworkCreate? - same as above
///   Student only
///     submissionCreate/submissionEdit/submissionView for homework submission

import Common
import CoreData
import DateToolsSwift
import UIKit

class HomeworkListViewController: UITableViewController {

    private struct SortingConfiguration {
        let keypath: String
        let sortDescriptor: String
        let cellIdentifier: String
    }

    private enum SortingMode {
        case dueDate
        case course

        var title: String {
            switch self {
            case .dueDate:
                return "Abgabetermin"
            case .course:
                return "Kurs"
            }
        }

        var configuration: SortingConfiguration {
            switch self {
            case .dueDate:
                return SortingConfiguration(keypath: "dueDateShort", sortDescriptor: "dueDate", cellIdentifier: "task")
            case .course:
                return SortingConfiguration(keypath: "course.name", sortDescriptor: "course.name", cellIdentifier: "courseTask")
            }
        }

        static var allValues = [SortingMode.dueDate, SortingMode.course]
    }

    private var selectedSortingStyle = SortingMode.dueDate {
        didSet {
            self.fetchedResultsController = self.makeFetchedResultsController(for: self.selectedSortingStyle.configuration)
            self.performFetch()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "HomeworkHeaderView", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "HomeworkHeaderView")

        self.performFetch()
        self.updateData()
    }

    @IBAction func sortOptionPressed(_ sender: Any) {
        let controller = UIAlertController(title: "Aufgaben sortieren nach", message: nil, preferredStyle: .actionSheet)

        for sortingStyle in SortingMode.allValues {
            let action = UIAlertAction(title: sortingStyle.title, style: .default) { [weak self] _ in
                self?.selectedSortingStyle = sortingStyle
            }

            controller.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        controller.addAction(cancelAction)

        self.present(controller, animated: true)
    }

    @IBAction func didTriggerRefresh() {
        self.updateData()
    }

    func updateData() {
        HomeworkHelper.syncHomework().onSuccess { _ in
            self.performFetch()
        }.onFailure { error in
            log.error(error)
        }.onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }

    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Homework> = {
        return self.makeFetchedResultsController(for: self.selectedSortingStyle.configuration)
    }()

    private func makeFetchedResultsController(for configuration: SortingConfiguration) -> NSFetchedResultsController<Homework> {
        let now = Date()
        let today: NSDate = Date(year: now.year, month: now.month, day: now.day) as NSDate

        let fetchRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: configuration.sortDescriptor, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@", today)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataHelper.viewContext,
                                                                  sectionNameKeyPath: configuration.keypath,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self

        return fetchedResultsController
    }

    func performFetch() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch let fetchError as NSError {
            log.error("Unable to Perform Fetch Request: \(fetchError), \(fetchError.localizedDescription)")
        }

        self.tableView.reloadData()
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections?[section].objects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let state = selectedSortingStyle.configuration
        let cell = tableView.dequeueReusableCell(withIdentifier: state.cellIdentifier, for: indexPath)

        let homework = self.fetchedResultsController.object(at: indexPath)
        if let homeworkCell = cell as? HomeworkByDateCell {
            homeworkCell.configure(for: homework)
        }

        if let upcomingHomeworkCell = cell as? HomeworkByCourseCell {
            upcomingHomeworkCell.configure(with: homework)
        }

        return cell
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
        let result = CoreDataHelper.viewContext.fetchSingle(fetchRequest)

        let title: String
        var backgroundColor: UIColor?

        if let course = result.value,
           let colorString = course.colorString {
            title = course.name
            backgroundColor = UIColor(hexString: colorString)
        } else {
            let date = Homework.shortDateFormatter.date(from: sectionInfo.name)!
            title = HomeworkByCourseCell.formatter.string(from: date)
        }

        view.configure(title: title, withColor: backgroundColor)

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
            let homework = sender as! Homework
            detailVC.homework = homework
        default:
            super.prepare(for: segue, sender: sender)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension HomeworkListViewController: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }

}
