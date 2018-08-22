//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import FileProvider

class FolderEnumerator: NSObject, NSFileProviderEnumerator {

    let file: File
    init(file: File) {
        assert(file.isDirectory)
        self.file = file
    }

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {

        var items = Array(file.contents)
        if (page.rawValue as NSData) == NSFileProviderPage.initialPageSortedByDate {
            items = file.contents.sorted(by: { (file1, file2) -> Bool in
                return file1.createdAt < file2.createdAt
            })
        } else if (page.rawValue as NSData) == NSFileProviderPage.initialPageSortedByName {
            items = file.contents.sorted(by: { (file1, file2) -> Bool in
                return file1.name < file2.name
            })
        } else {
            observer.finishEnumeratingWithError(NSFileProviderError(.pageExpired))
        }

        observer.didEnumerate(items)
        observer.finishEnumerating(upTo: nil)
        /* TODO:
         - inspect the page to determine whether this is an initial or a follow-up request

         If this is an enumerator for a directory, the root container or all directories:
         - perform a server request to fetch directory contents
         If this is an enumerator for the active set:
         - perform a server request to update your local database
         - fetch the active set from your local database

         - inform the observer about the items returned by the server (possibly multiple times)
         - inform the observer that you are finished with this page
         */
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


class WorkingSetEnumerator: NSObject, NSFileProviderEnumerator {

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        /* TODO:
         - inspect the page to determine whether this is an initial or a follow-up request

         If this is an enumerator for a directory, the root container or all directories:
         - perform a server request to fetch directory contents
         If this is an enumerator for the active set:
         - perform a server request to update your local database
         - fetch the active set from your local database

         - inform the observer about the items returned by the server (possibly multiple times)
         - inform the observer that you are finished with this page
         */
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
