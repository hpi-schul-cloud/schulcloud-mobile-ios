//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import UIKit

public class LessonsViewController: UITableViewController {

    var course: Course!
    var fetchedResultDelegate: TableViewFetchedControllerDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchedResultDelegate = TableViewFetchedControllerDelegate(tableView: self.tableView)

        tableView.rowHeight = UITableViewAutomaticDimension
        self.title = course.name
        performFetch()
        updateData()
    }

    @IBAction func didTriggerRefresh() {
        updateData()
    }

    func updateData() {
        LessonHelper.syncLessons(for: self.course).onFailure { error in
            log.error(error)
        }.onComplete { _ in
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table view data source

    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Lesson> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Lesson> = Lesson.fetchRequest()

        // Configure Fetch Request
        fetchRequest.predicate = NSPredicate(format: "course == %@", self.course)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataHelper.viewContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)

        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self.fetchedResultDelegate

        return fetchedResultsController
    }()

    func performFetch() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch let fetchError as NSError {
            log.error("Unable to Perform Fetch Request: \(fetchError), \(fetchError.localizedDescription)")
        }

        tableView.reloadData()
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    public override func tableView(_ tableView: UITableView,
                                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "lessonCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        let lesson = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = lesson.name
        cell.detailTextLabel?.text = lesson.descriptionText
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case .some("singleLesson"):
            guard let currentUser = Globals.currentUser, currentUser.permissions.contains(.contentView) else {
                let controller = UIAlertController(forMissingPermission: .contentView)
                self.present(controller, animated: true)
                return
            }

            guard let selectedCell = sender as? UITableViewCell else { return }
            guard let indexPath = tableView.indexPath(for: selectedCell) else { return }
            guard let destination = segue.destination as? SingleLessonViewController else { return }
            let selectedLesson = fetchedResultsController.object(at: indexPath)
            destination.lesson = selectedLesson
        default:
            break
        }
    }
}
