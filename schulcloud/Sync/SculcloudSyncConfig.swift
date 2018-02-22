//
//  SculcloudSyncConfig.swift
//  schulcloud
//
//  Created by Max Bothe on 22.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import CoreData

struct SchulcloudSyncConfig : SyncConfig {

    var baseURL: URL = Constants.backend.url

    var requestHeaders: [String : String] = [
        "Authorization": Globals.account!.accessToken!
    ]

    var persistentContainer: NSPersistentContainer {
        return CoreDataHelper.persistentContainer
    }

}
