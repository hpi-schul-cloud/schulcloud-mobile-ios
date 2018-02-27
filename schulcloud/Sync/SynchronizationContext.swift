//
//  SynchronizationContext.swift
//  schulcloud
//
//  Created by Max Bothe on 13.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import CoreData
import Foundation

struct SynchronizationContext {

    let coreDataContext: NSManagedObjectContext
    let strategy: SyncStrategy
    var includedResourceData: [ResourceData] = []

}
