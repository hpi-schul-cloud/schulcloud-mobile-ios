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

import CoreData
import DateToolsSwift
import UIKit

class HomeworkViewController: UITableViewController {
    @IBOutlet weak private var segmentedControl: UISegmentedControl!

    struct VisualizationData {
        let keypath: String
        let sortDescriptor: String
        let cellIdentifier: String
    }

    let states = [VisualizationData(keypath: "dueDateShort", sortDescriptor: "dueDate", cellIdentifier: "task"),
                  VisualizationData(keypath: "course.name", sortDescriptor: "course.name", cellIdentifier: "courseTask")]

    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "UpcomingHomeworkHeaderView", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "UpcomingHomeworkHeaderView")

        self.performFetch()
        self.updateData()
    }

    @IBAction func changedVisualization(_ sender: Any) {
        let visualization = states[segmentedControl.selectedSegmentIndex]
        fetchedResultsController = makeFetchedResultsController(with: visualization.keypath, sortDescriptor: visualization.sortDescriptor)
        self.performFetch()
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
        let now = Date()
        let today: NSDate = Date(year: now.year, month: now.month, day: now.day) as NSDate

        let fetchRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@", today)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataHelper.viewContext,
                                                                  sectionNameKeyPath: "dueDateShort",
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self

        return fetchedResultsController
    }()

    func makeFetchedResultsController(with keypath: String, sortDescriptor: String) -> NSFetchedResultsController<Homework> {
        let now = Date()
        let today: NSDate = Date(year: now.year, month: now.month, day: now.day) as NSDate

        let fetchRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortDescriptor, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@", today)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataHelper.viewContext,
                                                                  sectionNameKeyPath: keypath,
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
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections?[section].objects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let state = states[segmentedControl.selectedSegmentIndex]
        let cell = tableView.dequeueReusableCell(withIdentifier: state.cellIdentifier, for: indexPath)

        let homework = self.fetchedResultsController.object(at: indexPath)
        if let homeworkCell = cell as? HomeworkTableViewCell {
            homeworkCell.configure(for: homework)
        }

        if let upcomingHomeworkCell = cell as? UpcomingHomeworkCell {
            upcomingHomeworkCell.configure(with: homework)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let sectionInfo = self.fetchedResultsController.sections![section]
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "UpcomingHomeworkHeaderView") as? UpcomingHomeworkHeaderView else {
            return nil
        }

        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", sectionInfo.name)
        let result = CoreDataHelper.viewContext.fetchSingle(fetchRequest)

        let title: String
        let backgroundColor: UIColor

        if let course = result.value,
           let colorString = course.colorString {
            title = course.name
            backgroundColor = UIColor(hexString: colorString)!
        } else {
            let date = Homework.shortDateFormatter.date(from: sectionInfo.name)!
            title = UpcomingHomeworkCell.formatter.string(from: date)
            backgroundColor = tableView.backgroundColor!
        }

        view.configure(title: title, backgroundColor: backgroundColor)

        return view
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "taskDetail"?:
            guard let detailVC = segue.destination as? HomeworkDetailViewController else { return }
            guard let cell = sender as? UITableViewCell else { return }
            guard let indexPath = self.tableView.indexPath(for: cell) else { return }
            let homework = self.fetchedResultsController.object(at: indexPath)
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

extension HomeworkViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }
}
