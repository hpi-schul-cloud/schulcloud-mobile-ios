//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData

struct SchulcloudSyncConfig: SyncConfig {

    var baseURL: URL = Constants.backend.url

    var requestHeaders: [String: String] = [
        "Authorization": Globals.account!.accessToken!,
    ]

    var persistentContainer: NSPersistentContainer {
        return CoreDataHelper.persistentContainer
    }

}
