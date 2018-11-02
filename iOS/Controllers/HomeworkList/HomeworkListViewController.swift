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

final class HomeworkListViewController: UIViewController {

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
        self.dateSortedContainerView.isHidden = false
        self.courseSortedContainerView.isHidden = true
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
}
