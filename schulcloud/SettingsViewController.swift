//
//  SettingsViewController.swift
//  schulcloud
//
//  Created by Carl Gödecken on 10.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import BrightFutures

private var currentEventKitSettings = CalendarEventHelper.EventKitSettings.current

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
        
        let switchView = UISwitch()
        self.synchronizeCalendarCell.accessoryView = switchView
        
        switchView.isOn = currentEventKitSettings.isSynchonized
        switchView.addTarget(self, action: #selector(synchronizeToCalendar(switchView:)), for: UIControlEvents.valueChanged)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        if selectedCell == logoutCell {
            LoginHelper.logout()
            let loginViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "login")
            present(loginViewController, animated: true, completion: nil)
        }
    }
    
    func synchronizeToCalendar(switchView: UISwitch) {
        
        let newValue = switchView.isOn
        if newValue {
            
            CalendarEventHelper.fetchCalendarEvent(inContext: managedObjectContext)
                .flatMap { events -> Future< Void, SCError> in
                    
                    guard let calendar = CalendarEventHelper.fetchCalendar() ?? CalendarEventHelper.createCalendar() else {
                        return Future(error: .other("Can't access calendar") )
                    }
                    
                    do {
                        try CalendarEventHelper.push(events: events, to: calendar)
                    } catch let error {
                        return Future(error: .other(error.localizedDescription) )
                    }
                    return Future(value: Void() )
                }
                .onSuccess { _ in
                    DispatchQueue.main.async {
                        currentEventKitSettings.isSynchonized = true
                        switchView.isOn = true
                    }
                }
                .onFailure { error in
                    // TODO: Show error message as to why it failed
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: error.localizedDescription)
                        currentEventKitSettings.isSynchonized = false
                        switchView.isOn = false
                    }
            }
            
        } else {
            
            do {
                try CalendarEventHelper.deleteSchulcloudCalendar()
                currentEventKitSettings.isSynchonized = false
                switchView.isOn = false
            } catch let error {
                //TODO: Show error on why we could not delete the calendar
                self.showErrorAlert(message: error.localizedDescription)
                currentEventKitSettings.isSynchonized = true
                switchView.isOn = true
            }
        }
        
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Somthing went wrong", message: message, preferredStyle: .alert)
        self.present(alert, animated: true)
    }
}
