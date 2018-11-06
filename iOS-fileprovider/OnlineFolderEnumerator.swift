//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import FileProvider


fileprivate let nameSortDesc = NSSortDescriptor(key: "name", ascending: true)
fileprivate let dateSortDesc = NSSortDescriptor(key: "createdAt", ascending: true)

class OnlineFolderEnumerator: NSObject, NSFileProviderEnumerator {

    let itemIdentifier: NSFileProviderItemIdentifier
    let parentIdentifier: NSFileProviderItemIdentifier
    var fileSync: FileSync
    let context: NSManagedObjectContext

    var itemCountChanged = false
    var itemMetadataChanges = false
    lazy var fetchedResultsController: NSFetchedResultsController<File> = {
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parentDirectory.id == %@", itemIdentifier.rawValue)
        fetchRequest.sortDescriptors = [nameSortDesc]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.context,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController

    }()

    init(itemIdentifier: NSFileProviderItemIdentifier, fileSync: FileSync) {
        self.itemIdentifier = itemIdentifier

        self.fileSync = fileSync
        self.context = CoreDataHelper.persistentContainer.newBackgroundContext()
        self.context.automaticallyMergesChangesFromParent = true

        let file = File.by(id: itemIdentifier.rawValue, in: self.context)!
        // ROOT never uses OnlineFolderEnumerator
        self.parentIdentifier = NSFileProviderItemIdentifier(rawValue: file.parentDirectory!.id)

        super.init()
    }

    func invalidate() { }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        let id = itemIdentifier.rawValue // NOTE: It is assumed the root container doesn't make use of online enumeration
        guard let file = File.by(id: id, in: self.fetchedResultsController.managedObjectContext) else {
            observer.finishEnumeratingWithError(NSFileProviderError(.noSuchItem))
            return
        }

        if page == NSFileProviderPage.initialPageSortedByDate as NSFileProviderPage {
            self.fetchedResultsController.fetchRequest.sortDescriptors = [dateSortDesc]
            try? self.fetchedResultsController.performFetch()
        } else if page == NSFileProviderPage.initialPageSortedByName as NSFileProviderPage {
            self.fetchedResultsController.fetchRequest.sortDescriptors = [nameSortDesc]
            try? self.fetchedResultsController.performFetch()
        }

        self.fileSync.updateContent(of: file, completionBlock: { _ in })?.resume()
        let objects = self.fetchedResultsController.fetchedObjects ?? []
        observer.didEnumerate(objects.map(FileProviderItem.init(file:)))
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

extension OnlineFolderEnumerator: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.itemCountChanged = false
        self.itemMetadataChanges = false
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.itemCountChanged = true
        case .delete:
            self.itemCountChanged = true
        case .move:
            break
        case .update:
            guard let file = anObject as? File else { return }
            self.itemMetadataChanges = self.itemMetadataChanges || !file.changedValues().isEmpty
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if self.itemMetadataChanges || self.itemCountChanged {
            if self.itemCountChanged {
                NSFileProviderManager.default.signalEnumerator(for: self.parentIdentifier, completionHandler: { _ in })
            }
            NSFileProviderManager.default.signalEnumerator(for: self.itemIdentifier, completionHandler: { _ in })
        }
    }
}
