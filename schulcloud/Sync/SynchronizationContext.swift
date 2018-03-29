//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation

struct SynchronizationContext {

    let coreDataContext: NSManagedObjectContext
    let strategy: SyncStrategy
    var includedResourceData: [ResourceData] = []

}
