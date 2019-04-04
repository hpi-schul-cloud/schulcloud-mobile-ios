//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import SyncEngine

struct SchulcloudSyncConfig: SyncConfig {

    var baseURL: URL = Brand.default.servers.backend

    var requestHeaders: [String: String] {
        return [
            "Authorization": Globals.account!.accessToken!,
            "Content-Type": "application/json",
        ]
    }

    var persistentContainer: NSPersistentContainer {
        return CoreDataHelper.persistentContainer
    }

}
