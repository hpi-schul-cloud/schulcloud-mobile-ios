//
//  Notifications.swift
//  schulcloud
//
//  Created by Carl Gödecken on 12.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Alamofire
import BrightFutures
import Foundation

// firebase messaging
import UserNotifications
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

class SCNotifications {
    
    static func checkRegistration() -> Future<Void, SCError> {
        var deviceToken: String!
        
        return connectFirMessaging()
            .flatMap { token -> Future<Data, SCError> in
                deviceToken = token
                return ApiHelper.request("notification/devices").dataFuture()
            }
            .flatMap { data -> Future<Void, SCError> in
                if let string = String(data: data, encoding: .utf8),  // low-effort JSON parsing
                string.range(of: deviceToken) != nil {
                    log.debug("Device was already registered to receive push notifications for this account")
                    return connectFirMessaging().flatMap { _ in return Future(value: Void()) }
                } else {
                    return registerDevice(with: deviceToken)
                }
        }
    }
    
    static internal func connectFirMessaging() -> Future<String, SCError> {
        let promise = Promise<String, SCError>()
        FIRMessaging.messaging().disconnect()
        FIRMessaging.messaging().connect { error in
            if let error = error {
                promise.failure(SCError.firebase(error))
            } else {
                let token = FIRInstanceID.instanceID().token()!
                promise.success(token)
            }
        }
        return promise.future
    }
    
    static func registerDevice(with deviceToken: String) -> Future<Void, SCError> {
            log.debug("Registering the device with the notification service...")
            let parameters = [
                "service": "firebase",
                "type": "mobile",
                "name": "iOS device",
                "token": Globals.account!.userId,
                "device_token": deviceToken,
                "OS": "ios"
            ]
            return ApiHelper.requestBasic("notification/devices", method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .flatMap { response -> Future<Void, SCError> in
                    if let response = response.response, response.statusCode < 300 {
                        Globals.account!.didRegisterForPushNotifications = true
                        log.debug("Successfully registered device to receive notifications")
                        
                        return Future(value: Void())
                    } else if let afError = response.error {
                        return Future<Void, SCError>(error: SCError.network(afError))
                    } else {
                        return Future<Void, SCError>(error: SCError(apiResponse: response.data))
                    }
            }
        
    }
    
    static func initializeMessaging() {
        UNUserNotificationCenter.current().delegate = UIApplication.shared.delegate as! AppDelegate
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, error in
                if let error = error {
                    log.error(error)
                }
        })
        
        
        FIRMessaging.messaging().remoteMessageDelegate = RemoteMessageDelegate.shared
        
        UIApplication.shared.registerForRemoteNotifications()
        
        SCNotifications.checkRegistration().onFailure { error in
            log.error(error.localizedDescription)
        }
        
        UNUserNotificationCenter.current().delegate = RemoteMessageDelegate.shared
    }
    
    
}

class RemoteMessageDelegate: NSObject, FIRMessagingDelegate, UNUserNotificationCenterDelegate {
    static let shared = RemoteMessageDelegate()
    
    public func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        
        let content = UNMutableNotificationContent()
        
        if let newsString = remoteMessage.appData["news"] as? String,
            let newsData = newsString.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: newsData, options: []) as? [String: Any] {
            content.title = parsed?["title"] as? String ?? "Schul-Cloud-Benachrichtigung"
            content.body = parsed?["body"] as? String ?? ""
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
            // Create the request object.
            let request = UNNotificationRequest(identifier: "LocalFIRMessagingNotification", content: content, trigger: trigger)
            
            // dispatch the notification
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error : Error?) in
                if let theError = error {
                    log.error(theError.localizedDescription)
                }
            }
            
        } else {
            log.error("Could not read remote message \(remoteMessage.appData)")
        }
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(UNNotificationPresentationOptions.alert)
    }
}

extension SchulCloudAccount {
    var didRegisterForPushNotifications: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "didRegisterForPushNotifications\(userId)")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "didRegisterForPushNotifications\(userId)")
        }
    }
}
