//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import Security

public struct SchulCloudAccount {

    public var userId: String
    public var accountId: String
    public var accessToken: String?

    fileprivate enum KeychainError: Error {
        case itemAlreadyExists
        case itemDoesNotExist

        case unknown

        init(osstatus: OSStatus) {
            switch osstatus {
            case errSecDuplicateItem:
                self = KeychainError.itemAlreadyExists
            case errSecItemNotFound:
                self = KeychainError.itemDoesNotExist
            default:
                self = KeychainError.unknown
            }
        }
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

// MARK: Keychain stuff
extension SchulCloudAccount {

    func createInSecureStore() throws {
        guard let accessToken = accessToken else {
            return
        }

        let accessTokenData = accessToken.data(using: .utf8)

        var query = self.keychainQuery()
        query[kSecValueData as String] = accessTokenData as AnyObject

        let osstatus = SecItemAdd(query as CFDictionary, nil)
        guard osstatus == noErr else { throw KeychainError(osstatus: osstatus) }
    }

    func updateInSecureStore() throws {
        guard let accessToken = accessToken else {
            return
        }

        let accessTokenData = accessToken.data(using: .utf8)

        let query = self.keychainQuery()
        let attributeToUpdate: [String: AnyObject?] = [kSecValueData as String: accessTokenData as AnyObject]

        let osstatus = SecItemUpdate(query as CFDictionary, attributeToUpdate as CFDictionary)
        guard osstatus == noErr else { throw KeychainError(osstatus: osstatus) }
    }

    mutating func readFromSecureStore() throws {
        var query = self.keychainQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne as AnyObject
        query[kSecReturnData as String] = kCFBooleanTrue as AnyObject
        query[kSecReturnAttributes as String] = kCFBooleanTrue as AnyObject

        var result: AnyObject?
        let osstatus = withUnsafeMutablePointer(to: &result) {
            return SecItemCopyMatching(query as CFDictionary, $0)
        }

        guard osstatus == noErr else { throw KeychainError(osstatus: osstatus) }
        guard let entry = result as? [String: AnyObject],
              let accessTokenData = entry[kSecValueData as String] as? Data,
              let accessToken = String(data: accessTokenData, encoding: .utf8) else {
                throw KeychainError.unknown
        }

        self.accessToken = accessToken
    }

    func deleteFromSecureStore() throws {
        let query = self.keychainQuery()
        let osstatus = SecItemDelete(query as CFDictionary)
        guard osstatus == noErr else { throw KeychainError(osstatus: osstatus) }
    }

    private func keychainQuery() -> [String: AnyObject?] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.userId as AnyObject,
            kSecAttrService as String: Brand.default.name as AnyObject,
            kSecAttrAccessGroup as String: Bundle.main.keychainGroupIdentifier as AnyObject,
        ]
    }
}

public enum Globals {
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
