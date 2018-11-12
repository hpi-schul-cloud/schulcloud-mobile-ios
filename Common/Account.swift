//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import Locksmith

public struct SchulCloudAccount: ReadableSecureStorable, DeleteableSecureStorable, SecureStorableResultType {

    public var userId: String
    public var accountId: String
    public var accessToken: String?

    mutating func loadAccessTokenFromKeychain() {
        let result = self.readFromSecureStore()
        self.accessToken = result?.data?["accessToken"] as? String
    }

    func saveCredentials() throws {
        let defaults = UserDefaults.appGroupDefaults

        defaults?.set(self.accountId, forKey: "accountId")
        defaults?.set(self.userId, forKey: "userId")

        do {
            try self.createInSecureStore()
        } catch {
            try self.updateInSecureStore()
        }
    }

}

extension SchulCloudAccount: GenericPasswordSecureStorable {

    public var service: String {
        return "Schul-Cloud"
    }

    public var account: String {
        return self.userId
    }

}

extension SchulCloudAccount: CreateableSecureStorable {

    public var data: [String: Any] {
        return ["accessToken": self.accessToken as AnyObject]
    }

}

public class Globals {
    public static var account: SchulCloudAccount?

    public static var currentUser: User? {
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
