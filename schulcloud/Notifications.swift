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
        if Globals.account.didRegisterForPushNotifications {
            log.debug("Device was already registered to receive push notifications for this account")
            return connectFirMessaging().flatMap { _ in return Future(value: Void()) }
        } else {
            return registerDevice()
        }
    }
    
    static internal func connectFirMessaging() -> Future<String, SCError> {
        let promise = Promise<String, SCError>()
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
    
    static func registerDevice() -> Future<Void, SCError> {
        return connectFirMessaging().flatMap { deviceToken -> Future<Void, SCError> in
            log.debug("Registering the device with the notification service...")
            let parameters = [
                "service": "firebase",
                "type": "mobile",
                "name": "iOS device",
                "token": Globals.account.userId,
                "device_token": deviceToken,
                "OS": "ios"
            ]
            return ApiHelper.requestBasic("notification/devices", method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .flatMap { response -> Future<Void, SCError> in
                
                    if let response = response.response, response.statusCode < 300 {
                        Globals.account.didRegisterForPushNotifications = true
                        log.debug("Successfully registered device to receive notifications")
                        return Future(value: Void())
                    } else if let scError = SCError(apiResponse: response.data) {
                        return Future<Void, SCError>(error: scError)
                    } else {
                        return Future<Void, SCError>(error: SCError.network(response.error))
                    }
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
    }
    
    
}

class RemoteMessageDelegate: NSObject, FIRMessagingDelegate {
    static let shared = RemoteMessageDelegate()
    
    public func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print(remoteMessage.appData)
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
