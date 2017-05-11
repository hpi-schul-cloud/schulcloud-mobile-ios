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

    internal static func getAccessToken(username: String?, password: String?) -> Future<String, LoginError> {
        let promise = Promise<String, LoginError>()
        
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
    
    static func login(username: String?, password: String?) -> Future<Void, LoginError> {
        return getAccessToken(username: username, password: password).flatMap { accessToken -> Future<Void, LoginError> in
            do {
                let jwt = try decode(jwt: accessToken)
                let accountId = jwt.body["accountId"] as! String
                let userId = jwt.body["userId"] as! String
                let account = SchulCloudAccount(userId: userId, accountId: accountId, accessToken: accessToken)
                defaults.set(account.accountId, forKey: "accountId")
                defaults.set(account.userId, forKey: "userId")
                try account.createInSecureStore()
                log.info("Successfully saved login data for user \(userId) with account \(accountId)")
                Globals.account = account
                return Future(value: Void())
            } catch let error {
                return Future(error: LoginError.loginFailed(error.localizedDescription))
            }
        }
    }
    
    static func logout() {
        defaults.set(nil, forKey: "accountId")
        defaults.set(nil, forKey: "userId")
        do {
            try Globals.account.deleteFromSecureStore()
        } catch let error {
            log.error(error.localizedDescription)
        }
    }
    
}

enum LoginError: Error {
    case loginFailed(String)
    case wrongCredentials
    case unknown
}

extension LoginError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .loginFailed(let message):
            return "Fehler: \(message)"
        case .wrongCredentials:
            return "Fehler: Falsche Anmeldedaten"
        case .unknown:
            return "Unbekannter Fehler"
        }
    }
}
