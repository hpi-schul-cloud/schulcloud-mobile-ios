//
//  DashboardHomeworkCell.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

class DashboardHomeworkCell: UITableViewCell {

    @IBOutlet var numberOfOpenTasksLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        numberOfOpenTasksLabel.text = "?"
            NotificationCenter.default.addObserver(self, selector: #selector(DashboardHomeworkCell.updateHomeworkCount), name: NSNotification.Name(rawValue: Homework.changeNotificationName), object: nil)
        updateHomeworkCount()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateHomeworkCount() {
        let fetchRequest: NSFetchRequest<Homework> = Homework.fetchRequest()
        let oneWeek = DateComponents(day: 8)
        let inOneWeek = Calendar.current.date(byAdding: oneWeek, to: Date())!
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ && dueDate <= %@ ", argumentArray: [Date() as NSDate, inOneWeek as NSDate])
        do {
            let resultsInNextWeek = try managedObjectContext.fetch(fetchRequest)
            numberOfOpenTasksLabel.text = String(resultsInNextWeek.count)
        } catch let error {
            log.error(error)
        }
    }

}
