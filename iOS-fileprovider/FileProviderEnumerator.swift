//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import FileProvider

class FileEnumerator: NSObject, NSFileProviderEnumerator {
    let file: File

    init(file: File) {
        assert(!file.isDirectory)
        self.file = file
        super.init()
    }

    func invalidate() {
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {

    }

    func enumerateChanges(for observer: NSFileProviderChangeObserver, from syncAnchor: NSFileProviderSyncAnchor) {

    }
}

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
        let items = context.performAndWait { () -> [File] in
            let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
            fetchRequest.predicate = NSPredicate(format: "parentDirectory.id == %@", id)
            fetchRequest.sortDescriptors = [sortDescriptor]

            let result = context.fetchMultiple(fetchRequest)
            guard let files = result.value else {
                observer.finishEnumeratingWithError(result.error!)
                return []
            }
            return files
        }.map(FileProviderItem.init(file:))

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

class OnlineFolderEnumerator: NSObject, NSFileProviderEnumerator {

    static var dateCompareFunc: (File, File) -> Bool = { $0.createdAt < $1.createdAt }
    static var nameCompareFunc: (File, File) -> Bool = { $0.name < $1.name }
    
    var itemIdentifier: NSFileProviderItemIdentifier
    var fileSync: FileSync

    var compareFunc: (File, File) -> Bool = OnlineFolderEnumerator.nameCompareFunc

    init(itemIdentifier: NSFileProviderItemIdentifier, fileSync: FileSync) {
        self.itemIdentifier = itemIdentifier
        self.fileSync = fileSync
        super.init()
    }

    func invalidate() { }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {

        let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
        fetchRequest.predicate = NSPredicate(format: "id == %@", self.itemIdentifier.rawValue)

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        guard let file = context.fetchSingle(fetchRequest).value else {
            observer.finishEnumeratingWithError(NSFileProviderError(.noSuchItem))
            return
        }

        if page == NSFileProviderPage.initialPageSortedByDate as NSFileProviderPage {
            self.compareFunc = OnlineFolderEnumerator.dateCompareFunc
        } else if page == NSFileProviderPage.initialPageSortedByName as NSFileProviderPage {
            self.compareFunc = OnlineFolderEnumerator.nameCompareFunc
        }

        fileSync.updateContent(of: file).onSuccess { files in
            let ids = files.sorted(by: self.compareFunc).map { $0.objectID }
            DispatchQueue.main.async {
                let localItems = ids.map { CoreDataHelper.viewContext.typedObject(with: $0) as File }.map(FileProviderItem.init(file:))
                observer.didEnumerate(localItems)
                observer.finishEnumerating(upTo: nil)
            }
        }.onFailure { error in
            DispatchQueue.main.async {
                observer.finishEnumeratingWithError(error)
            }
        }
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

    var itemsTable: [NSFileProviderItemIdentifier: FileProviderItem] = [:]

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }

    init(workingSet: [File]) {
        var itemsTable = [NSFileProviderItemIdentifier: FileProviderItem] ()
        for item in workingSet.map(FileProviderItem.init(file:)) {
            itemsTable[item.itemIdentifier] = item
        }
        self.itemsTable = itemsTable
        super.init()
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        let files = Array<FileProviderItem>(self.itemsTable.values)

        observer.didEnumerate(files as [NSFileProviderItem])
        observer.finishEnumerating(upTo: nil)
    }

    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        var updatedFiles = [FileProviderItem]()
        var deletedFiles = [NSFileProviderItemIdentifier]()

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
        fetchRequest.predicate = FileHelper.workingSetPredicate

        let fetchResult = context.fetchMultiple(fetchRequest)
        guard let files = fetchResult.value else {
            observer.finishEnumeratingWithError(fetchResult.error!)
            return
        }

        let items = files.map(FileProviderItem.init(file:))

        var currentWorkingTable = [NSFileProviderItemIdentifier: FileProviderItem]()
        for item in items {
            currentWorkingTable[item.itemIdentifier] = item
        }

        for (key, oldItem) in self.itemsTable {
            if let newItem = currentWorkingTable[key] {
                if  oldItem.lastUsedDate != newItem.lastUsedDate ||
                    oldItem.tagData != newItem.tagData ||
                    oldItem.favoriteRank != newItem.favoriteRank ||
                    oldItem.isTrashed != newItem.isTrashed ||
                    oldItem.isShared != newItem.isShared {
                    updatedFiles.append(newItem)
                }
            } else {
                deletedFiles.append(key)
            }
        }

        for (key, addedItem) in currentWorkingTable {
            if self.itemsTable[key] == nil {
                updatedFiles.append(addedItem)
            }
        }

        observer.didUpdate(updatedFiles)
        observer.didDeleteItems(withIdentifiers: deletedFiles)

        let result = context.fetchSingle(WorkingSetSyncAnchor.mainAnchorFetchRequest)
        let anchor: WorkingSetSyncAnchor = result.value!

        let data = Data(buffer: UnsafeBufferPointer(start: &anchor.value, count: 1))

        observer.finishEnumeratingChanges(upTo: NSFileProviderSyncAnchor(data), moreComing: false)
        self.itemsTable = currentWorkingTable
    }

    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        let result = context.fetchSingle(WorkingSetSyncAnchor.mainAnchorFetchRequest)
        let anchor: WorkingSetSyncAnchor = result.value!

        let data = Data(buffer: UnsafeBufferPointer(start: &anchor.value, count: 1))
        completionHandler(NSFileProviderSyncAnchor(data))
    }
}
