//
//  LoginHelper.swift
//  schulcloud
//
//  Created by Carl Gödecken on 10.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Alamofire
import BrightFutures
import Locksmith
import JWTDecode

open class LoginHelper {
    
    static let defaults = UserDefaults.standard

    internal static func getAccessToken(username: String?, password: String?) -> Future<String, SCError> {
        let promise = Promise<String, SCError>()
        
        let parameters: Parameters = [
            "username": username as Any,
            "password": password as Any
        ]
        
        let loginEndpoint = Constants.backend.url.appendingPathComponent("authentication/")
        Alamofire.request(loginEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            guard let json = response.result.value as? [String: Any] else {
                let error = response.error!
                promise.failure(.loginFailed(error.localizedDescription))   // using the error directly isn't possible because Error can't be used as a concrete type
                return
            }
            if let accessToken = json["accessToken"] as? String {
                promise.success(accessToken)
            } else if let errorMessage = json["message"] as? String, errorMessage != "Error" {
                promise.failure(.loginFailed(errorMessage))
            } else if json["code"] as? Int == 401 {
                promise.failure(.wrongCredentials)
            } else {
                promise.failure(.unknown)
            }
        }
        
        return promise.future
    }
    
    static func login(username: String?, password: String?) -> Future<Void, SCError> {
        return getAccessToken(username: username, password: password).flatMap(saveToken)
    }
    
    static func saveToken(accessToken: String) -> Future<Void, SCError> {
        do {
            let jwt = try decode(jwt: accessToken)
            let accountId = jwt.body["accountId"] as! String
            let userId = jwt.body["userId"] as! String
            let account = SchulCloudAccount(userId: userId, accountId: accountId, accessToken: accessToken)
            defaults.set(account.accountId, forKey: "accountId")
            defaults.set(account.userId, forKey: "userId")
            do {
                try account.createInSecureStore()
            } catch {
                try account.updateInSecureStore()
            }
            log.info("Successfully saved login data for user \(userId) with account \(accountId)")
            Globals.account = account
            SCNotifications.initializeMessaging()
            return Future(value: Void())
        } catch let error {
            return Future(error: SCError.loginFailed(error.localizedDescription))
        }
    }
    
    static func renewAccessToken() -> Future<Void, SCError> {
        return ApiHelper.request("authentication", method: .post).jsonObjectFuture()
            .flatMap { response -> Future<Void, SCError> in
                if let accessToken = response["accessToken"] as? String {
                    return saveToken(accessToken: accessToken)
                } else {
                    return Future(error: SCError(json: response))
                }
        }
    }
    
    static func logout() {
        defaults.set(nil, forKey: "accountId")
        defaults.set(nil, forKey: "userId")
        do {
            try Globals.account!.deleteFromSecureStore()
        } catch let error {
            log.error(error.localizedDescription)
        }
    }
    
}
