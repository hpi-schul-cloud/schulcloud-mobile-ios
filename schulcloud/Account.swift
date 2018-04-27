//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import Locksmith

struct SchulCloudAccount: CreateableSecureStorable, ReadableSecureStorable, DeleteableSecureStorable, GenericPasswordSecureStorable, SecureStorableResultType {

    var userId: String
    var accountId: String

    var accessToken: String?

    // Required by GenericPasswordSecureStorable
    let service = "Schul-Cloud"
    var account: String { return userId }

    // Required by CreateableSecureStorable
    var data: [String: Any] {
        return ["accessToken": accessToken as AnyObject]
    }

    mutating func loadAccessTokenFromKeychain() {
        let result = readFromSecureStore()
        accessToken = result?.data?["accessToken"] as? String
    }

    func saveCredentials() throws {
        let defaults = UserDefaults.shared

        defaults?.set(accountId, forKey: "accountId")
        defaults?.set(userId, forKey: "userId")

        do {
            try createInSecureStore()
        } catch {
            try updateInSecureStore()
        }
    }
}

class Globals {
    static var account: SchulCloudAccount?

    static var currentUser: User? {
        guard let userId = account?.userId else { return nil }
        return CoreDataHelper.viewContext.performAndWait { () -> User? in
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", userId)

            switch CoreDataHelper.viewContext.fetchSingle(fetchRequest) {
            case .success(let user):
                return user
            case .failure(let error):
                print("Failure fetching self user: \(error)")
                return nil
            }
        }
    }
}
