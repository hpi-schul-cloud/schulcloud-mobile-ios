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
import FirebaseMessaging
import Firebase

class SCNotifications {
    
    static func checkRegistration() -> Future<Void, NSError> {
        if Globals.account.didRegisterForPushNotifications {
            return Future(value: Void())
        } else {
            return registerDevice()
        }
    }
    
    static internal func connectFirMessaging() -> Future<String, NSError> {
        let promise = Promise<String, NSError>()
        FIRMessaging.messaging().connect { error in
            if let error = error {
                promise.failure(error as NSError)
            } else {
                let token = FIRInstanceID.instanceID().token()!
                promise.success(token)
            }
        }
        return promise.future
    }
    
    static func registerDevice() -> Future<Void, NSError> {
        return connectFirMessaging().flatMap { deviceToken -> Future<Void, NSError> in
            let parameters = [
                "service": "firebase",
                "type": "mobile",
                "name": "iOS device",
                "token": Globals.account.userId,
                "device_token": deviceToken,
                "OS": "ios"
            ]
            return ApiHelper.requestBasic("notification/devices", method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .flatMap { response -> Future<Void, NSError> in
                
                    if let response = response.response, response.statusCode < 300 {
                        Globals.account.didRegisterForPushNotifications = true
                        log.debug("Successfully registered device to receive notifications")
                        return Future(value: Void())
                    } else {
                        return Future<Void, NSError>(error: response.error? as NSError ?? NSError(domain: "schulcloud", code: response.response?.statusCode ?? 0, userInfo: nil)
                    }
            }
        }
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
