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
        
        self.synchronizeCalendarCell.detailTextLabel!.text = currentEventKitSettings.isSynchonized ? "On" : "Off"
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        if selectedCell == logoutCell {
            LoginHelper.logout()
            let loginViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "login")
            present(loginViewController, animated: true, completion: nil)
        }
        
        if selectedCell == synchronizeCalendarCell {
            let newValue = !currentEventKitSettings.isSynchonized
            if newValue {
                
                CalendarEventHelper.fetchCalendarEvent(inContext: managedObjectContext)
                .flatMap { events -> Future< Void, SCError> in
                    
                    var calendar = CalendarEventHelper.fetchCalendar()
                    if calendar == nil { calendar = CalendarEventHelper.createCalendar() }
                    guard let foundCalendar = calendar else { return Future(error: .other("Can't access calendar") ) }
                    
                    do {
                        try CalendarEventHelper.push(events: events, to: foundCalendar)
                    } catch let error {
                        return Future(error: .other(error.localizedDescription) )
                    }
                    return Future(value: Void() )
                }
                .onSuccess { _ in
                    currentEventKitSettings.isSynchonized = true
                    self.synchronizeCalendarCell.detailTextLabel!.text = "On"
                }
                .onFailure { error in
                    // TODO: Show error message as to why it failed
                    currentEventKitSettings.isSynchonized = false
                    self.synchronizeCalendarCell.detailTextLabel!.text = "Off"
                }
                
            } else {
                
                do {
                    try CalendarEventHelper.deleteSchulcloudCalendar()
                    currentEventKitSettings.isSynchonized = false
                    self.synchronizeCalendarCell.detailTextLabel!.text = "Off"
                } catch let error {
                    //TODO: Show error on why we could not delete the calendar
                    currentEventKitSettings.isSynchonized = true
                    self.synchronizeCalendarCell.detailTextLabel!.text = "On"
                }
                
            }
        }
    }
}
