//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation

public protocol SyncConfig {
    // Requests
    var baseURL: URL { get }
    var requestHeaders: [String: String] { get }

    // Core Data
    var persistentContainer: NSPersistentContainer { get }

}
