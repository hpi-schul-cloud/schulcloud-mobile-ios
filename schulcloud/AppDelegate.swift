//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Firebase
import SwiftyBeaver
import UIKit
import UserNotifications

let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    var tabBarController: UITabBarController? {
        return self.window?.rootViewController as? UITabBarController
    }

    static var instance: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // set up SwiftyBeaver
        let console = ConsoleDestination()  // log to Xcode Console
        console.levelColor.warning = "❗️ "
        console.levelColor.debug = "🔍 "
        console.levelColor.error = "❌ "
        console.levelColor.info = "👉 "
        log.addDestination(console)

        if !isUnitTesting() {
            FIRApp.configure()
        }

        self.window?.tintColor = UIColor.schulcloudRed
        selectInitialViewController(application: application)

        CoreDataObserver.shared.startObserving()

        return true
    }

    let storyboard = UIStoryboard(name: "Main", bundle: nil)

    fileprivate func showLogin() {
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "login")
        self.window?.rootViewController = loginViewController
    }

    /// Check for existing login credentials and return appropriate view controller
    func selectInitialViewController(application: UIApplication) {
        if UserDefaults.standard.bool(forKey: "forceLogin") {
            showLogin()
            return
        }

        guard let account = LoginHelper.loadAccount() else {
            showLogin()
            return
        }

        guard let validAccount = LoginHelper.validate(account) else {
            LoginHelper.logout()
            showLogin()
            return
        }

        // skip login
        prepareInitialViewController(with: validAccount)
    }

    func prepareInitialViewController(with account: SchulCloudAccount) {
        Globals.account = account
        SCNotifications.initializeMessaging()
        LoginHelper.renewAccessToken()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        CoreDataHelper.viewContext.saveWithResult()
    }

    func isUnitTesting() -> Bool {
        return ProcessInfo.processInfo.environment["TEST"] != nil
    }
}

extension AppDelegate: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let userID = Globals.account?.userId else { return false }
        let user_ = CoreDataHelper.viewContext.performAndWait { () -> User? in
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", userID)
            return CoreDataHelper.viewContext.fetchSingle(fetchRequest).value
        }

        guard let user = user_ else { return false }
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
        let alertController = UIAlertController(title: "Permission Error", message: "You are not allowed to access this feature. \(missingPermission)", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(alertAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
}
