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
    @IBOutlet var calendarSyncSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.calendarSyncSwitch.isOn = currentEventKitSettings.isSynchonized

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
    }
    
    @IBAction func synchronizeToCalendar(_ sender: UISwitch) {
        let newValue = sender.isOn
        if newValue {
            CalendarEventHelper.requestCalendarPermission()
            .flatMap { _ -> Future<[CalendarEvent], SCError> in
                   return CalendarEventHelper.fetchCalendarEvent(inContext: managedObjectContext)
            }
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
                    sender.isOn = true
                }
            }
            .onFailure { error in
                // TODO: Show error message as to why it failed
                DispatchQueue.main.async {
                    self.showErrorAlert(message: error.localizedDescription)
                    currentEventKitSettings.isSynchonized = false
                    sender.isOn = false
                }
            }
        } else {
            do {
                try CalendarEventHelper.deleteSchulcloudCalendar()
                currentEventKitSettings.isSynchonized = false
                sender.isOn = false
            } catch let error {
                //TODO: Show error on why we could not delete the calendar
                self.showErrorAlert(message: error.localizedDescription)
                currentEventKitSettings.isSynchonized = true
                sender.isOn = true
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(dismiss)
        self.present(alert, animated: true)
    }
}
