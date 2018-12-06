//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import CoreData
import UIKit

private var currentEventKitSettings = CalendarEventHelper.EventKitSettings.current

class SettingsViewController: UITableViewController {

    @IBOutlet private var logoutCell: UITableViewCell!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var schoolNameLabel: UILabel!
    @IBOutlet private var calendarSyncSwitch: UISwitch!

    private var user: User? {
        didSet {
            if self.user != oldValue {
                DispatchQueue.main.async {
                    let names = [self.user?.firstName, self.user?.lastName].compactMap { $0 }
                    self.userNameLabel.text = names.joined(separator: " ")
                }
            }
        }
    }

    private var school: School? {
        didSet {
            if self.school != oldValue {
                DispatchQueue.main.async {
                    self.schoolNameLabel.text = self.school?.name
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

        UserHelper.syncUser(withId: userId).andThen { result in
            switch result {
            case .failure(_):
                break
            case .success(let syncResult):
                let userObjectID = syncResult.objectId
                guard let user = (try? CoreDataHelper.viewContext.existingObject(with: userObjectID)) as? User else {
                    return
                }

                self.user = user
                if let schoolId = user.schoolId {
                    SchoolHelper.syncSchool(withId: schoolId).onSuccess { res in
                        let schoolObjectID = res.objectId
                        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
                        context.performAndWait {
                            let user = context.typedObject(with: userObjectID) as User
                            let school = context.typedObject(with: schoolObjectID) as School

                            user.school = school
                            context.saveWithResult()
                        }

                        let school = CoreDataHelper.viewContext.typedObject(with: schoolObjectID) as School
                        self.school = school
                    }
                }
            }
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
        if sender.isOn {
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
                // TODO: Show error on why we could not delete the calendar
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
