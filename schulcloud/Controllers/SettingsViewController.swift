//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit
import BrightFutures
import CoreData

private var currentEventKitSettings = CalendarEventHelper.EventKitSettings.current

class SettingsViewController: UITableViewController {

    @IBOutlet var logoutCell: UITableViewCell!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet var calendarSyncSwitch: UISwitch!

    private var user: User? {
        didSet {
            if self.user != oldValue {
                DispatchQueue.main.async {
                    let names = [self.user?.firstName, self.user?.lastName].flatMap { $0 }
                    self.userNameLabel.text = names.joined(separator: " ")
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let userId = Globals.account?.userId else { return }

        CoreDataHelper.viewContext.perform {
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", userId)
            if case let .success(user) = CoreDataHelper.viewContext.fetchSingle(fetchRequest) {
                self.user = user
            }
        }

        UserHelper.syncUser(withId: userId).onSuccess { syncResult in
            guard let user = CoreDataHelper.viewContext.existingTypedObject(with: syncResult.objectId) as? User else {
                log.warning("Failed to retrieve user to display")
                return
            }

            self.user = user
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.calendarSyncSwitch.isOn = currentEventKitSettings.shouldSynchonize && CalendarEventHelper.currentCalenderPermissionStatus == .authorized
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
            CalendarEventHelper.requestCalendarPermission().flatMap { _ in
                   return CalendarEventHelper.fetchCalendarEvents(inContext: CoreDataHelper.viewContext)
            }.flatMap { events -> Future<Void, SCError> in
                guard let calendar = CalendarEventHelper.fetchCalendar() ?? CalendarEventHelper.createCalendar() else {
                    return Future(error: .other("Can't access calendar") )
                }

                do {
                    try CalendarEventHelper.push(events: events, to: calendar)
                } catch let error {
                    return Future(error: .other(error.localizedDescription) )
                }

                return Future(value: ())
            }.onSuccess { _ in
                DispatchQueue.main.async {
                    currentEventKitSettings.shouldSynchonize = true
                    sender.isOn = true
                }
            }.onFailure { error in
                // TODO: Show error message as to why it failed
                DispatchQueue.main.async {
                    self.showErrorAlert(message: error.localizedDescription)
                    currentEventKitSettings.shouldSynchonize = false
                    sender.isOn = false
                }
            }
        } else {
            do {
                try CalendarEventHelper.deleteSchulcloudCalendar()
                currentEventKitSettings.shouldSynchonize = false
                sender.isOn = false
            } catch let error {
                //TODO: Show error on why we could not delete the calendar
                self.showErrorAlert(message: error.localizedDescription)
                currentEventKitSettings.shouldSynchonize = true
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
