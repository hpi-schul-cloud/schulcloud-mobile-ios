//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import CoreData
import SafariServices
import UIKit

private var currentEventKitSettings = CalendarEventHelper.EventKitSettings.current

class SettingsViewController: UITableViewController {

    @IBOutlet private var logoutCell: UITableViewCell!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private var calendarSyncSwitch: UISwitch!

    @IBOutlet private weak var imprintCell: UITableViewCell!
    @IBOutlet private weak var dataUsageCell: UITableViewCell!

    private var observer: NSObjectProtocol?

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

        NotificationCenter.default.removeObserver(self.tableView as Any, name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableViewData), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    @objc func reloadTableViewData() {
        self.tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.calendarSyncSwitch.isOn = currentEventKitSettings.shouldSynchonize && CalendarEventHelper.currentCalenderPermissionStatus == .authorized
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) else { return }

        switch selectedCell {
        case logoutCell:
            LoginHelper.logout()
            let loginViewController = R.storyboard.main.login()!
            if #available(iOS 13, *) {
                loginViewController.modalPresentationStyle = .fullScreen
            }
            self.present(loginViewController, animated: true, completion: nil)
        case imprintCell:
            let safariViewController = SFSafariViewController(url: Brand.default.imprintURL)
            safariViewController.preferredControlTintColor = Brand.default.colors.primary
            self.present(safariViewController, animated: true)
        case dataUsageCell:
            let safariViewController = SFSafariViewController(url: Brand.default.dataPrivacyURL)
            safariViewController.preferredControlTintColor = Brand.default.colors.primary
            self.present(safariViewController, animated: true)
        default:
            break
        }
    }

    @IBAction private func synchronizeToCalendar(_ sender: UISwitch) {
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
