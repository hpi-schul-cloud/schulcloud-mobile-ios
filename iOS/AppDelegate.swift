//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import Firebase
import UIKit
import UserNotifications

let log = Logger(subsystem: "org.schulcloud", category: "iOS")

@UIApplicationMain
public class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    public var window: UIWindow?

    var tabBarController: UITabBarController? {
        return self.window?.rootViewController as? UITabBarController
    }

    static var instance: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.customizeAppearance()

        if !isUnitTesting() {
            FirebaseApp.configure()
        }

        selectInitialViewController(application: application)

        CoreDataObserver.shared.startObserving()
        LoginHelper.setupAuthentication(authenticationHandler: self.presentAuthenticationScreen)

        return true
    }

    private func customizeAppearance() {
        self.window?.tintColor = Brand.default.colors.primary

        let navigationBarAppearance = UINavigationBar.appearance()
        let offWhite = UIColor(white: 0.98, alpha: 1.0)
        navigationBarAppearance.barTintColor = Brand.default.colors.primary
        navigationBarAppearance.tintColor = offWhite
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: offWhite]
        navigationBarAppearance.shadowImage = UIImage()

        if #available(iOS 11, *) {
            navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: offWhite]
        }
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
        guard !ProcessInfo.processInfo.arguments.contains("-DropDB") else {
            LoginHelper.logout()
            self.window?.rootViewController = self.loginViewController
            return
        }
        
        if let modelEntities = UserDefaults.standard.dictionary(forKey: "entityHashes") as? [String: Data] {
            let currentEntityHashes = CoreDataHelper.managedObjectModel.entityVersionHashesByName
            if modelEntities.keys.sorted() == currentEntityHashes.keys.sorted() {
                for key in modelEntities.keys where modelEntities[key] != currentEntityHashes[key] {
                    UserDefaults.standard.set(currentEntityHashes, forKey: "entityHashes")
                    LoginHelper.logout()
                    self.window?.rootViewController = self.loginViewController
                    return
                }
            }
        } else {
            UserDefaults.standard.set(CoreDataHelper.managedObjectModel.entityVersionHashesByName, forKey: "entityHashes")
        }

        // skip login
        Globals.account = validAccount
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
