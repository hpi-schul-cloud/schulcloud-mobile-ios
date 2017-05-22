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
import AlamofireObjectMapper
import ObjectMapper



class DashboardViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getNotifications()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 2:
            //we are in notification section
            return notifications.count
        default:
            return 1
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "currentLesson")!
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "tasks")!
            return cell
        case 2:
            //we are in notification section
            let cell = tableView.dequeueReusableCell(withIdentifier: "notification")!
            let label = cell.viewWithTag(1) as! UILabel
            let notification = notifications[indexPath.row]
            label.text = notification.title
            return cell
        default:
            fatalError("unknown Section Index")
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
       let url = Constants.backend.url.absoluteString + "notification?$limit=50"
        let headers: HTTPHeaders = [
            "Authorization": Globals.account!.accessToken!
        ]
        Alamofire.request(url, headers: headers).responseArray(keyPath: "data") {(response: DataResponse<[SCNotification]>) in
            if let notifications = response.result.value{
                self.notifications = notifications
                self.tableView.reloadData()
            }
        }
    }
    
    
}

struct SCNotification: Mappable {
    var body:String!
    var title:String!
    var action:URL!
    
    init?(map: Map) {
    }
    mutating func mapping(map: Map) {
      body  <- map["message.body"]
      title <- map["message.title"]
      action <- (map["message.action"], URLTransform(shouldEncodeURLString: false ))
    }
}
