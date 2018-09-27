//
//  WorkingSetEnumerator.swift
//  iOS-fileprovider
//
//  Created by Florian Morel on 27.09.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Common
import CoreData
import FileProvider

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
        let files = [FileProviderItem](self.itemsTable.values)

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

        for (key, addedItem) in currentWorkingTable where self.itemsTable[key] != nil {
            updatedFiles.append(addedItem)
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
