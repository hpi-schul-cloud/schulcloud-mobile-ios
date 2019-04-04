//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Foundation
import JWTDecode
import Locksmith
import Result

public extension UserDefaults {
    public static var appGroupDefaults: UserDefaults? {
        guard let suiteName = Bundle.main.appGroupIdentifier else { return nil }
        return UserDefaults(suiteName: suiteName)
    }
}

public class LoginHelper {

    /// Setup the sync engine with the callback needed when an authentication error happens
    public static func setupAuthentication(authenticationHandler: @escaping () -> Void) {
        SyncHelper.authenticationChallengerHandler = authenticationHandler
    }

    public static func getAccessToken(username: String, password: String) -> Future<String, SCError> {
        let parameters = [
            "username": username as Any,
            "password": password as Any,
        ]

        guard let requestBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return Future(error: SCError.jsonSerialization("Can't serialize login parameter"))
        }

        var headers = ["Content-Type": "application/json"]
        if let accessToken = Globals.account?.accessToken {
            headers["Authorization"] = accessToken
        }

        let loginEndpoint = Brand.default.servers.backend.appendingPathComponent("authentication/")
        var request = URLRequest(url: loginEndpoint)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields? = headers
        request.httpBody = requestBody

        let promise = Promise<String, SCError>()
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                promise.failure(.network(error))
                return
            }

            guard let response = response as? HTTPURLResponse else {
                promise.failure(.network(nil))
                return
            }

            guard 200...299 ~= response.statusCode else {
                if let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                    promise.failure(SCError(json: json))
                } else {
                    promise.failure(SCError.apiError(response.statusCode, ""))
                }

                return
            }

            guard let data = data else {
                promise.failure(.network(nil))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let jsonDict = json as? [String: Any] {
                    if let accessToken = jsonDict["accessToken"] as? String {
                        promise.success(accessToken)
                    } else {
                        promise.failure(.jsonDeserialization("No accessToken field found"))
                    }
                } else {
                    promise.failure(.jsonDeserialization("Unexpected json format"))
                }
            } catch let error {
                promise.failure(SCError.jsonDeserialization(error.localizedDescription))
            }
        }.resume()

        return promise.future
    }

    public static func authenticate(username: String, password: String) -> Future<Void, SCError> {
        return getAccessToken(username: username, password: password).flatMap(saveToken)
    }

    public static func login(username: String, password: String) -> Future<Void, SCError> {
        return self.authenticate(username: username, password: password).flatMap { _ in
            return UserHelper.syncUser(withId: Globals.account!.userId)
        }.onSuccess{ (_) in
            FileHelper.createBaseStructure()
        }.asVoid()
    }

    public static func saveToken(accessToken: String) -> Future<Void, SCError> {
        do {
            let jwt = try decode(jwt: accessToken)
            guard let accountId = jwt.body["accountId"] as? String, let userId = jwt.body["userId"] as? String else {
                return Future(error: SCError.loginFailed("Did not receive account id and user id"))
            }

            let account = SchulCloudAccount(userId: userId, accountId: accountId, accessToken: accessToken)
            try account.saveCredentials()
            log.info("Successfully saved login data for user %@ with account %@", userId, accountId)
            Globals.account = account
//            DispatchQueue.main.async {
//                SCNotifications.initializeMessaging()
//            }

            return Future(value: Void())
        } catch let error {
            return Future(error: SCError.loginFailed(error.localizedDescription))
        }
    }

    public static func loadAccount() -> SchulCloudAccount? {
        guard let defaults = UserDefaults.appGroupDefaults,
            let accountId = defaults.string(forKey: "accountId"),
            let userId = defaults.string(forKey: "userId") else {
            return nil
        }

        var account = SchulCloudAccount(userId: userId, accountId: accountId, accessToken: nil)
        account.loadAccessTokenFromKeychain()

        return account
    }

    public static func validate(_ account: SchulCloudAccount) -> SchulCloudAccount? {
        guard let accessToken = account.accessToken else {
            log.error("Could not load access token for account!")
            return nil
        }

        guard let jwt = try? decode(jwt: accessToken) else {
            log.error("Error validating token")
            return nil
        }

        guard let expirationDate = jwt.expiresAt else {
            log.error("Could not find experiation date - better fail")
            return nil
        }

        let threeHourBuffer: TimeInterval = 60 * 60 * 3
        let isValid = Date() < expirationDate - threeHourBuffer
        return isValid ? account : nil
    }

    public static func logout() {
        UserDefaults.appGroupDefaults?.set(nil, forKey: "accountId")
        UserDefaults.appGroupDefaults?.set(nil, forKey: "userId")

        do {
            CoreDataHelper.clearCoreDataStorage()
            try Globals.account!.deleteFromSecureStore()
            Globals.account = nil
            try CalendarEventHelper.deleteSchulcloudCalendar()
        } catch {
            log.error("Unexpected error during logout", error: error)
        }
    }
}
