//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import Firebase
import SwiftyBeaver
import UIKit
import UserNotifications

let log = Common.log

@UIApplicationMain
public class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    public var window: UIWindow?

    var tabBarController: UITabBarController? {
        return self.window?.rootViewController as? UITabBarController
    }

    static var instance: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        self.window?.tintColor = Brand.default.colors.primary

        // set up SwiftyBeaver
        let console = ConsoleDestination()  // log to Xcode Console
        console.levelColor.warning = "❗️ "
        console.levelColor.debug = "🔍 "
        console.levelColor.error = "❌ "
        console.levelColor.info = "👉 "
        log.addDestination(console)

        if !isUnitTesting() {
            FirebaseApp.configure()
        }

        selectInitialViewController(application: application)

        CoreDataObserver.shared.startObserving()
        LoginHelper.setupAuthentication(authenticationHandler: self.presentAuthenticationScreen)

        return true
    }

    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    var loginViewController: UIViewController {
        return storyboard.instantiateViewController(withIdentifier: "login")
    }

    func presentAuthenticationScreen() {
        DispatchQueue.main.async {
            self.window?.rootViewController?.present(self.loginViewController, animated: true, completion: nil)
        }
    }

    /// Check for existing login credentials and return appropriate view controller
    func selectInitialViewController(application: UIApplication) {
        if UserDefaults.standard.bool(forKey: "forceLogin") {
            self.window?.rootViewController = self.loginViewController
            return
        }

        guard let account = LoginHelper.loadAccount() else {
            self.window?.rootViewController = self.loginViewController
            return
        }

        guard let validAccount = LoginHelper.validate(account) else {
            LoginHelper.logout()
            self.window?.rootViewController = self.loginViewController
            return
        }

        // skip login
        prepareInitialViewController(with: validAccount)
    }

    func prepareInitialViewController(with account: SchulCloudAccount) {
        Globals.account = account
        SCNotifications.initializeMessaging()
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        CoreDataHelper.viewContext.saveWithResult()
    }

    func isUnitTesting() -> Bool {
        return ProcessInfo.processInfo.environment["TEST"] != nil
    }
}

extension AppDelegate: UITabBarControllerDelegate {

    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let userID = Globals.account?.userId else { return false }

        let fetchedUser = CoreDataHelper.viewContext.performAndWait { () -> Common.User? in
            let fetchRequest: NSFetchRequest<Common.User> = Common.User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", userID)
            return CoreDataHelper.viewContext.fetchSingle(fetchRequest).value
        }

        guard let user = fetchedUser else { return false }
        guard let navController = viewController as? UINavigationController else { return false }
        guard let rootViewController = navController.viewControllers.first else { return false }

        if rootViewController is DashboardViewController, !user.permissions.contains(.dashboardView) {
            self.showError(on: tabBarController, missingPermission: .dashboardView)
            return false
        }

        if rootViewController is NewsListViewController, !user.permissions.contains(.newsView) {
            self.showError(on: tabBarController, missingPermission: .newsView)
            return false
        }

        if rootViewController is LessonsViewController, !user.permissions.contains(.lessonsView) {
            self.showError(on: tabBarController, missingPermission: .lessonsView)
            return false
        }

        if rootViewController is FilesViewController, !user.permissions.contains(.filestorageView) {
            self.showError(on: tabBarController, missingPermission: .filestorageView)
            return false
        }

        return true
    }

    func showError(on viewController: UIViewController, missingPermission: UserPermissions) {
        let alertController = UIAlertController(title: "Permission Error",
                                                message: "You are not allowed to access this feature. \(missingPermission)",
                                                preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(alertAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
}
