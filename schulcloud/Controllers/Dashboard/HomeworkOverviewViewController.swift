//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import UIKit

class HomeworkOverviewViewController: UIViewController {

    @IBOutlet private var numberOfOpenTasksLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.numberOfOpenTasksLabel.text = "?"
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateHomeworkCount),
                                               name: Homework.homeworkCountDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangePreferredContentSize),
                                               name: NSNotification.Name.UIContentSizeCategoryDidChange,
                                               object: nil)
        self.updateHomeworkCount()
        self.didChangePreferredContentSize()
    }

    @objc func updateHomeworkCount() {
        CoreDataHelper.viewContext.perform {
            let fetchRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
            let oneWeek = DateComponents(day: 8)
            let inOneWeek = Calendar.current.date(byAdding: oneWeek, to: Date())!
            fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ && dueDate <= %@ ", argumentArray: [Date() as NSDate, inOneWeek as NSDate])
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
            do {
                let resultsInNextWeek = try CoreDataHelper.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
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
            } catch {
                log.error(error)
            }
        }
    }

    @objc func didChangePreferredContentSize() {
        var font = UIFont.preferredFont(forTextStyle: .title1)
        font = font.withSize(font.pointSize * 3)
        self.numberOfOpenTasksLabel.font = font
    }

}

extension HomeworkOverviewViewController: ViewControllerHeightDataSource {
    var height: CGFloat { return 200 }
}
