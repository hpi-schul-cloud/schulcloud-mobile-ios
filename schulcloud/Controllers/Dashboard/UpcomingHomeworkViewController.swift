//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class UpcomingHomeworkViewController: UITableViewController {

    var upcomingHomeworks: [Course: [Homework]]? = nil

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

        view.configure(title: course.name, backgroundColor: UIColor(hexString: course.colorString!)!)

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

        cell.configure(with: homework)

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
