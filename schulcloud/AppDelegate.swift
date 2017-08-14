    //
//  AppDelegate.swift
//  schulcloud
//
//  Created by Carl Gödecken on 05.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import Firebase

import SwiftyBeaver
let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // set up SwiftyBeaver
        let console = ConsoleDestination()  // log to Xcode Console
        console.levelColor.warning = "❗️ "
        console.levelColor.debug = "🔍 "
        console.levelColor.error = "❌ "
        console.levelColor.info = "👉 "
        log.addDestination(console)
        
        FIRApp.configure()
        
        let initialViewController = selectInitialViewController(application: application)
        self.window?.rootViewController = initialViewController
        
        observeChanges()
        
        return true
    }
    
    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
    
    /// Check for existing login credentials and return appropriate view controller
    func selectInitialViewController(application: UIApplication) -> UIViewController {
        if let validAccount = LoginHelper.loadAccount() {
            return prepareInitialViewController(with: validAccount)
        } else {
            log.info("Could not find existing login credentials, proceeding to login")
            return storyboard.instantiateViewController(withIdentifier: "login")
        }
    }
    
    func prepareInitialViewController(with account: SchulCloudAccount) -> UIViewController {
        Globals.account = account
        
        let initialViewController = storyboard.instantiateInitialViewController()!
        
        SCNotifications.initializeMessaging()
        ApiHelper.updateData()
        return initialViewController
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
        saveContext()
    }

    // MARK: temp core data observer
    func observeChanges() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
    }
    
    func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
            print("--- INSERTS ---")
            print(inserts)
            print("+++++++++++++++")
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
            print("--- UPDATES ---")
            var unchanged = 0
            for update in updates {
                let changed = update.changedValues()
                if changed.count > 0 {
                    print(changed)
                } else {
                    unchanged += 1
                }
            }
            print("\(unchanged) unchanged")
            print("+++++++++++++++")
        }
        
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
            print("--- DELETES ---")
            print(deletes)
            print("+++++++++++++++")
        }
    }
    
    
}

