//
//  HomeworkOverviewViewController.swift
//  schulcloud
//
//  Created by Max Bothe on 11.10.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

class HomeworkOverviewViewController: UIViewController {

    @IBOutlet var numberOfOpenTasksLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.numberOfOpenTasksLabel.text = "?"
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didChangePreferredContentSize),
                                               name: NSNotification.Name.UIContentSizeCategoryDidChange,
                                               object: nil)
        self.updateHomeworkCount()
        self.didChangePreferredContentSize()
    }

    func updateHomeworkCount() {
        let fetchRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
        let oneWeek = DateComponents(day: 8)
        let inOneWeek = Calendar.current.date(byAdding: oneWeek, to: Date())!
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ && dueDate <= %@ ", argumentArray: [Date() as NSDate, inOneWeek as NSDate])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        do {
            let resultsInNextWeek = try CoreDataHelper.managedObjectContext.fetch(fetchRequest)
            DispatchQueue.main.async {
                self.numberOfOpenTasksLabel.text = String(resultsInNextWeek.count)
            }
            if let nextTask = resultsInNextWeek.first {
                DispatchQueue.main.async {
                    self.subtitleLabel.isHidden = false
                }
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
            } else {
                DispatchQueue.main.async {
                    self.subtitleLabel.isHidden = true
                }
            }
        } catch let error {
            log.error(error)
        }
    }

    @objc func didChangePreferredContentSize() {
        var font = UIFont.preferredFont(forTextStyle: .title1)
        font = font.withSize(font.pointSize * 3)
        self.numberOfOpenTasksLabel.font = font
    }

}
