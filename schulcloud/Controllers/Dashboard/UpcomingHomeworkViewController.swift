//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class UpcomingHomeworkCell : UITableViewCell {
    @IBOutlet weak var title : UILabel!
    @IBOutlet weak var dueDate: UILabel!
    @IBOutlet weak var descriptionText : UILabel!
}

final class UpcomingHomeworkHeaderView : UITableViewHeaderFooterView {
    @IBOutlet weak var label: UILabel!
}

final class UpcomingHomeworkViewController : UITableViewController {

    lazy var formatter : DateComponentsFormatter = {
        let componentFormatter = DateComponentsFormatter()
        componentFormatter.unitsStyle = .abbreviated
        return componentFormatter
    }()

    var upcomingHomeworks : [Course : [Homework]]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "UpcomingHomeworkHeaderView", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "UpcomingHomeworkHeaderView")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return upcomingHomeworks?.keys.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let upcomingHomeworks = upcomingHomeworks else { return 0 }

        var index = upcomingHomeworks.keys.startIndex
        upcomingHomeworks.formIndex(&index, offsetBy: section)

        let course = upcomingHomeworks.keys[index]
        let homeworks = upcomingHomeworks[course]
        return homeworks?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let upcomingHomeworks = upcomingHomeworks,
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "UpcomingHomeworkHeaderView") as? UpcomingHomeworkHeaderView else { return nil }

        var index = upcomingHomeworks.keys.startIndex
        upcomingHomeworks.formIndex(&index, offsetBy: section)
        let course = upcomingHomeworks.keys[index]

        if view.backgroundView == nil {
            view.backgroundView = UIView()
        }
        let backgroundView = view.backgroundView
        backgroundView?.backgroundColor = UIColor(hexString: course.colorString!)
        view.label.text = course.name

        return view
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UpcomingHomework") as! UpcomingHomeworkCell

        guard let upcomingHomeworks = upcomingHomeworks else { return cell }

        var index = upcomingHomeworks.keys.startIndex
        upcomingHomeworks.formIndex(&index, offsetBy: indexPath.section)

        let course = upcomingHomeworks.keys[index]
        let homeworks = upcomingHomeworks[course]!
        let homework = homeworks[indexPath.row]

        cell.title?.text = homework.name
        cell.dueDate?.text = "\(formatter.string(from: Date(), to: homework.dueDate)!) left"
        let description = homework.cleanedDescriptionText
        if let attributedString = NSMutableAttributedString(html: description) {
            let range = NSRange(location: 0, length: attributedString.string.count)
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .body), range: range)
            cell.descriptionText.text = attributedString.trailingNewlineChopped.string
        } else {
            cell.descriptionText.text = description
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let upcomingHomeworks = upcomingHomeworks else { return }
        var index = upcomingHomeworks.keys.startIndex
        upcomingHomeworks.formIndex(&index, offsetBy: indexPath.section)

        let course = upcomingHomeworks.keys[index]
        let homeworks = upcomingHomeworks[course]!
        let homework = homeworks[indexPath.row]

        self.performSegue(withIdentifier: "taskDetail", sender: homework)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "taskDetail" {
            guard let detailVC = segue.destination as? HomeworkDetailViewController else { return }
            guard let homework = sender as? Homework else { return }
            detailVC.homework = homework
        }
    }
}
