//
//  SettingsViewController.swift
//  schulcloud
//
//  Created by Carl Gödecken on 10.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet var logoutCell: UITableViewCell!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var synchronizeCalendarCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let userId = Globals.account?.userId else { return }
        User.fetch(by: userId, inContext: managedObjectContext).onSuccess { user in
            self.userNameLabel.text = "\(user.firstName) \(user.lastName)"
        }.onFailure { error in
            self.userNameLabel.text = ""
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        if selectedCell == logoutCell {
            LoginHelper.logout()
            let loginViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "login")
            present(loginViewController, animated: true, completion: nil)
        }
        
        if selectedCell == synchronizeCalendarCell {
            CalendarSettings.eventKitSynchronized = !CalendarSettings.eventKitSynchronized
        }
    }

}

struct CalendarSettings {
    
    private static var eventKitSynchronizedKey = "org.schulcloud.eventKitSynchronizedKey"
    static var eventKitSynchronized : Bool {
        get {
            return UserDefaults.standard.bool(forKey: eventKitSynchronizedKey)
        }
        
        set {
            UserDefaults.standard.set( newValue, forKey: eventKitSynchronizedKey)
            UserDefaults.standard.synchronize()
        }
    }
}
