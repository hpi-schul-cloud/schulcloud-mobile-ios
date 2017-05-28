//
//  DashboardViewController.swift
//  schulcloud
//
//  Created by jan on 22/05/2017.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//  TODO: cell Height


import UIKit
import BrightFutures
import Alamofire
import Marshal



class DashboardViewController: UITableViewController {

    enum Sections: Int {
        case today, tasks, notifications
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getNotifications()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.notifications.rawValue:
            //we are in notification section
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
        case Sections.tasks.rawValue:
            break
        case Sections.notifications.rawValue:
            let notification = self.notifications[indexPath.row]
            let alertController = UIAlertController(title: notification.title, message: notification.body, preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                //print("You pressed OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        default:
            //we are in notification section
            let alertController = UIAlertController(title: "Ups", message: "No action here yet", preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                //print("You pressed OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Heute"
        case 1:
            return "Aufgaben"
        case 2:
            //we are in notification section
            return "Benachrichtungen"
        default:
            return "Section"
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view:UIView, forSection: Int) {
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.backgroundColor = UIColor.white
            headerTitle.contentView.backgroundColor = UIColor.white
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Sections(rawValue: indexPath.section)! {
        case .today:
            let cell = tableView.dequeueReusableCell(withIdentifier: "currentLesson")!
            return cell
        case .tasks:
            let cell = tableView.dequeueReusableCell(withIdentifier: "tasks")!
            return cell
        case .notifications:
            //we are in notification section
            let cell = tableView.dequeueReusableCell(withIdentifier: "notification")!
            let label = cell.viewWithTag(1) as! UILabel
            let notification = notifications[indexPath.row]
            label.text = notification.title
            return cell
        }
    
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 140.0
        case 1:
            return 100.0
        default:
            return 40.0        }

    }
    
    var notifications = [SCNotification]()
    
    func getNotifications(){
        let request: Future<[SCNotification], SCError> = ApiHelper.request("notification?$limit=50").deserialize(keyPath: "data")
        request.onSuccess { (notifications: [SCNotification]) in
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
