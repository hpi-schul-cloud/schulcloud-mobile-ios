//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import DateToolsSwift
import UIKit

protocol HomeworkOverviewDelegate: class {
    func heightDidChange(height: CGFloat)
    func didPressHomeworkList()
    func didPressTableView(homeworkData: [Course: [Homework]])
}

final class HomeworkOverviewViewController: UIViewController {
    @IBOutlet private weak var numberOfOpenTasksLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!

    lazy var resultController: NSFetchedResultsController<Homework> = {
        let fetchedRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
        fetchedRequest.sortDescriptors = []

        let result = NSFetchedResultsController(fetchRequest: fetchedRequest,
                                                managedObjectContext: CoreDataHelper.viewContext,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil)
        result.delegate = self
        return result
    }()

    weak var delegate: HomeworkOverviewDelegate?

    var organizedHomeworkData: [Course: [Homework]] = [:]
    var weekInterval: DateInterval {
        let now = Date()
        let today = Date(year: now.year, month: now.month, day: now.day)
        let weekChunk = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 0, weeks: 1, months: 0, years: 0)
        return DateInterval(start: today, end: today + weekChunk)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        self.numberOfOpenTasksLabel.text = "?"
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateHomeworkCount),
                                               name: Homework.homeworkCountDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangePreferredContentSize),
                                               name: NSNotification.Name.UIContentSizeCategoryDidChange,
                                               object: nil)

        HomeworkHelper.syncHomework()
        try! self.resultController.performFetch()
        self.updateHomeworkCount()
        self.didChangePreferredContentSize()
    }

    @objc func updateHomeworkCount() {
        let fetchedObject = (self.resultController.fetchedObjects ?? []) as [Homework]
        let resultsInNextWeek = fetchedObject.filter { homework -> Bool in
            return weekInterval.contains(homework.dueDate)
        }

        self.numberOfOpenTasksLabel.text = String(resultsInNextWeek.count)
        if let nextTask = resultsInNextWeek.first {
            let timeDifference = Calendar.current.dateComponents([.day, .hour], from: Date(), to: nextTask.dueDate as Date)
            switch timeDifference.day! {
            case 0..<1:
                self.subtitleLabel.text = "Nächste in \(timeDifference.hour!) Stunden fällig"
            case 1:
                self.subtitleLabel.text = "Nächste morgen fällig"
            case 2:
                self.subtitleLabel.text = "Nächste übermorgen fällig"
            case 3...7:
                self.subtitleLabel.text = "Nächste in \(timeDifference.day!) Tagen fällig"
            default:
                self.subtitleLabel.text = ""
            }

            self.subtitleLabel.isHidden = false
        } else {
            self.subtitleLabel.isHidden = true
        }
    }

    @objc func didChangePreferredContentSize() {
        var font = UIFont.preferredFont(forTextStyle: .title1)
        font = font.withSize(font.pointSize * 3)
        self.numberOfOpenTasksLabel.font = font
    }

    @IBAction func homeworkListPressed() {
        self.delegate?.didPressHomeworkList()
    }
}

extension HomeworkOverviewViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return organizedHomeworkData.keys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeworkOverviewCell") as! HomeworkOverviewCell

        var index = organizedHomeworkData.keys.startIndex
        organizedHomeworkData.formIndex(&index, offsetBy: indexPath.row)

        let course = organizedHomeworkData.keys[index]
        let homeworks = organizedHomeworkData[course]
        cell.configure(course: course, homeworkCount: homeworks?.count ?? 0)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: false)
        }

        self.delegate?.didPressTableView(homeworkData: organizedHomeworkData)
    }
}

extension HomeworkOverviewViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        organizedHomeworkData.removeAll()
        let fetchedObject = (controller.fetchedObjects ?? []) as! [Homework]
        let filterHomework = fetchedObject.filter { homework -> Bool in
            return weekInterval.contains(homework.dueDate)
        }

        var result = [Course: [Homework]]()

        for homework in filterHomework {
            guard let course = homework.course else { continue }
            if var homeworks = result[course] {
                homeworks.append(homework)
                result[course] = homeworks
            } else {
                result[course] = [homework]
            }
        }

        organizedHomeworkData =  [Course: [Homework]](pairs: result.sorted { $0.0.name < $1.0.name })
        self.updateHomeworkCount()
        tableView.reloadData()
        self.delegate?.heightDidChange(height: self.height)
    }
}

extension HomeworkOverviewViewController: ViewHeightDataSource {
    var height: CGFloat {
        return tableView.frame.minY + tableView.contentSize.height + 16.0
    }
}

extension HomeworkOverviewViewController: PermissionInfoDataSource {
    static let requiredPermission = UserPermissions.homeworkView
}
