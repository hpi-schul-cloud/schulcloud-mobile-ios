//
//  DashboardViewController.swift
//  schulcloud
//
//  Created by jan on 22/05/2017.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//


import UIKit

import Alamofire
import BrightFutures
import Marshal


class DashboardViewController: UITableViewController {

    enum Sections: Int {
        case today, tasks, notifications
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getNotifications()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.notifications.rawValue:
            return notifications.count
        default:
            return 1
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    //handle click
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Sections.notifications.rawValue:
            let notification = self.notifications[indexPath.row]
            let alertController = UIAlertController(title: notification.title, message: notification.body, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Sections.today.rawValue:
            return "Heute"
        case Sections.tasks.rawValue:
            return "Aufgaben"
        case Sections.notifications.rawValue:
            return "Benachrichtungen"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Sections(rawValue: indexPath.section)! {
        case .today:
            return tableView.dequeueReusableCell(withIdentifier: "currentLesson", for: indexPath)
        case .tasks:
            return tableView.dequeueReusableCell(withIdentifier: "tasks", for: indexPath)
        case .notifications:
            let cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath)
            let label = cell.viewWithTag(1) as! UILabel
            let notification = notifications[indexPath.row]
            label.text = notification.title
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Sections.today.rawValue:
            return 140.0
        case Sections.tasks.rawValue:
            return 100.0
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    var notifications = [SCNotification]()

    func getNotifications(){
        let request: Future<[SCNotification], SCError> = ApiHelper.request("notification?$limit=50").deserialize(keyPath: "data")
        request.onSuccess { notifications in
            self.notifications = notifications
            self.tableView.reloadData()
        }
    }

}

struct SCNotification: Unmarshaling {
    let body: String
    let title: String?
    let action: URL?

    init(object: MarshaledObject) throws {
        let message = try object.value(for: "message") as JSONObject
        body = try message.value(for: "body")
        title = try? message.value(for: "title")
        action = try? message.value(for: "action")
    }
}
