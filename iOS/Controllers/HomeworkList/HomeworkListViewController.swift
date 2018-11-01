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

protocol HomeworkDisplayDelegate: class {
    func display(homework: Homework)
}

final class HomeworkListViewController: UIViewController, HomeworkDisplayDelegate {

    @IBOutlet var courseSortedContainerView: UIView!
    @IBOutlet var dateSortedContainerView: UIView!

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
        static var allValues = [SortingMode.dueDate, SortingMode.course]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let courseSortedVC = self.childViewControllers.first{ $0 is HomeworkListCourseSortedViewController } as! HomeworkListCourseSortedViewController
        let dateSortedVC = self.childViewControllers.first{ $0 is HomeworkListDateSortedViewController } as! HomeworkListDateSortedViewController

        courseSortedVC.displayDelegate = self
        dateSortedVC.displayDelegate = self
    }

    private var selectedSortingStyle = SortingMode.dueDate {
        didSet {
            switch self.selectedSortingStyle {
            case .dueDate:
                self.dateSortedContainerView.isHidden = false
                self.courseSortedContainerView.isHidden = true
            case .course:
                self.dateSortedContainerView.isHidden = true
                self.courseSortedContainerView.isHidden = false
            }
        }
    }

    @IBAction func sortOptionPressed(_ sender: UIBarButtonItem) {
        let controller = UIAlertController(title: "Aufgaben sortieren nach", message: nil, preferredStyle: .actionSheet)

        for sortingStyle in SortingMode.allValues {
            let action = UIAlertAction(title: sortingStyle.title, style: .default) { [weak self] _ in
                self?.selectedSortingStyle = sortingStyle
            }

            controller.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        controller.addAction(cancelAction)

        controller.popoverPresentationController?.barButtonItem = sender

        self.present(controller, animated: true)
    }

    func display(homework: Homework) {
        self.performSegue(withIdentifier: "taskDetail", sender: homework)
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
