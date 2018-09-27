//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import FileProvider

class FolderEnumerator: NSObject, NSFileProviderEnumerator {

    let itemIdentifier: NSFileProviderItemIdentifier
    
    init(item: NSFileProviderItemIdentifier) {
        self.itemIdentifier = item
        super.init()
    }

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        let id = itemIdentifier == .rootContainer ? FileHelper.rootDirectoryID : itemIdentifier.rawValue
        let sortDescriptor =
            (page.rawValue as NSData == NSFileProviderPage.initialPageSortedByDate) ?
                NSSortDescriptor(key: "createdAt", ascending: true) :
                NSSortDescriptor(key: "name", ascending: true)

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        let items = context.performAndWait { () -> [FileProviderItem] in
            guard let files = File.with(parentId: id, in: context) else {
                observer.finishEnumeratingWithError(NSFileProviderError(.noSuchItem))
                return []
            }

            return files.sorted { sortDescriptor.compare($0, to: $1) == .orderedAscending }.map(FileProviderItem.init(file:))
        }

        observer.didEnumerate(items)
        observer.finishEnumerating(upTo: nil)
    }

    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        /* TODO:
         - query the server for updates since the passed-in sync anchor

         If this is an enumerator for the active set:
         - note the changes in your local database

         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
    }
}
