//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class HomeworkSubmitViewController: UITableViewController {

    private enum Section: Int, CaseIterable {
        case comment = 0
        case files
        case teacherComment
    }

    var submission: Submission?

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .comment:
            return "Comments"
        case .files:
            return "Files"
        case .teacherComment:
            return "Teacher's comment"
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { fatalError() }
        switch section {
        case .comment:
            return 1
        case .files:
            return submission?.files.count ?? 0
        case .teacherComment:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { fatalError() }

        var maybeCell = tableView.dequeueReusableCell(withIdentifier: "homeworkCell")
        if maybeCell == nil {
            maybeCell = UITableViewCell(style: .default, reuseIdentifier: "homeworkCell")
        }

        let cell = maybeCell!

        let files = Array(self.submission?.files ?? [])

        var text: String? = nil
        switch section {
        case .comment:
            text = self.submission?.comment
        case .files:
            text = files[indexPath.row].name
        case .teacherComment:
            cell.textLabel?.text = self.submission?.gradeComment
        }

        cell.textLabel?.text = text
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.files.rawValue
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard indexPath.section == Section.files.rawValue else { return nil }

        // TODO: implement action
        let removeAction = UITableViewRowAction(style: .destructive, title: "Remove") { (action, indexPath) in

        }

        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in

        }
        return [removeAction, deleteAction]
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == Section.files.rawValue else { return nil }
        // TODO: add section footer for files
        return nil
    }

}
