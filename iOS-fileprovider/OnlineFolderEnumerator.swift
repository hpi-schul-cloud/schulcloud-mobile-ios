//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import FileProvider

class OnlineFolderEnumerator: NSObject, NSFileProviderEnumerator {

    static var dateCompareFunc: (File, File) -> Bool = { $0.createdAt < $1.createdAt }
    static var nameCompareFunc: (File, File) -> Bool = { $0.name < $1.name }

    let itemIdentifier: NSFileProviderItemIdentifier
    var fileSync: FileSync

    var compareFunc: (File, File) -> Bool = OnlineFolderEnumerator.nameCompareFunc
    var items: [FileProviderItem] = []

    init(itemIdentifier: NSFileProviderItemIdentifier, fileSync: FileSync) {
        self.itemIdentifier = itemIdentifier
        self.fileSync = fileSync
        super.init()
    }

    func invalidate() { }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        let id = itemIdentifier.rawValue // NOTE: It is assumed the root container doesn't make use of online enumeration
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        guard let file = File.by(id: id, in: context) else {
            observer.finishEnumeratingWithError(NSFileProviderError(.noSuchItem))
            return
        }

        let parentProviderItemIdentifier = file.parentDirectory != nil ? FileProviderItem(file: file.parentDirectory!).itemIdentifier : nil

        if page == NSFileProviderPage.initialPageSortedByDate as NSFileProviderPage {
            self.compareFunc = OnlineFolderEnumerator.dateCompareFunc
        } else if page == NSFileProviderPage.initialPageSortedByName as NSFileProviderPage {
            self.compareFunc = OnlineFolderEnumerator.nameCompareFunc
        }

        fileSync.updateContent(of: file) { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    observer.finishEnumeratingWithError(error)
                }

            case .success(let files):
                let localItems = files.map { file in
                    return file.objectID
                }.map { id in
                    CoreDataHelper.viewContext.typedObject(with: id) as File
                }.sorted(by: self.compareFunc).map(FileProviderItem.init(file:))

                if let parentItemIdentifier = parentProviderItemIdentifier,
                    localItems.count != self.items.count {
                    NSFileProviderManager.default.signalEnumerator(for: parentItemIdentifier) { _ in }
                }

                self.items = localItems
                DispatchQueue.main.async {
                    observer.didEnumerate(localItems)
                    observer.finishEnumerating(upTo: nil)
                }
            }

        }?.resume()
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
