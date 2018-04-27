//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import FileProvider
import SwiftyBeaver
import CoreData
import BrightFutures

let log = SwiftyBeaver.self

class Course: NSObject {

}

class Homework: NSObject {

}

struct CalendarEventHelper {
    static func deleteSchulcloudCalendar() {
        
    }
}

struct SCNotifications {
    static func initializeMessaging() {

    }
}

class FileProviderExtension: NSFileProviderExtension {
    let root : File
    let fileSync = FileSync()

    override init() {
        guard let account = LoginHelper.loadAccount() else {
            fatalError()
        }

        guard let validAccount = LoginHelper.validate(account) else {
            fatalError()
        }
        Globals.account = validAccount
        root = FileHelper.rootFolder
        super.init()
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        // resolve the given identifier to a record in the model
        if identifier == NSFileProviderItemIdentifier.rootContainer {
            return FileProviderItem(file: root)
        }
        let file = File.file(with: identifier.rawValue)
        return FileProviderItem(file: file!)
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        let file = File.file(with: identifier.rawValue)
        return file?.url
    }
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        // resolve the given URL to a persistent identifier using a database

        guard let item = File.file(at: url, root: root) else {
            return nil
        }
        return NSFileProviderItemIdentifier(item.id)
    }
    
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }

        do {
            if #available(iOS 11.0, *) {
                let fileProviderItem = try item(for: identifier)
                let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
                try NSFileProviderManager.writePlaceholder(at: placeholderURL,withMetadata: fileProviderItem)
            } else {
                let file = File.file(at: url, root: root)
                try! NSFileProviderExtension.writePlaceholder(at: url, withMetadata: [URLResourceKey.isDirectoryKey : file!.isDirectory])
            }
            completionHandler(nil)

        } catch let error {
            completionHandler(error)
        }
    }

    override func startProvidingItem(at url: URL, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        // Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
        guard let item = File.file(at: url, root: root) else {
            completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:]))
            return
        }

        let successHandler : () -> Void = {
            completionHandler(nil)
        }
        let errorHandler : (SCError) -> Void = { error in
            completionHandler(error)
        }

        if item.isDirectory {
            fileSync.downloadContent(for: item)
            .flatMap { (json) -> Future<Void, SCError> in
                    return FileHelper.updateDatabase(contentsOf: item, using: json)
            }.onSuccess(callback: successHandler).onFailure(callback: errorHandler)
        } else {
            self.providePlaceholder(at: url) { _ in
                self.fileSync.signedURL(for: item).flatMap { [weak self] url -> Future<Data, SCError> in
                    return self!.fileSync.download(url: item.url, progressHandler: nil)
                    }.andThen { result in
                        if let data = result.value {

                            try! data.write(to: url)
                        }
                    }.asVoid().onSuccess(callback: successHandler).onFailure(callback: errorHandler)
            }
        }
    }
    
    
    override func itemChanged(at url: URL) {
        // Called at some point after the file has changed; the provider may then trigger an upload
        
        /* TODO:
         - mark file at <url> as needing an update in the model
         - if there are existing NSURLSessionTasks uploading this file, cancel them
         - create a fresh background NSURLSessionTask and schedule it to upload the current modifications
         - register the NSURLSessionTask with NSFileProviderManager to provide progress updates
         */
    }
    
    override func stopProvidingItem(at url: URL) {
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        // Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.
        
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        
        // TODO: look up whether the file has local changes
        let fileHasLocalChanges = false
        
        if !fileHasLocalChanges {
            // remove the existing file to free up space
            do {
                _ = try FileManager.default.removeItem(at: url)
            } catch {
                // Handle error
            }
            
            // write out a placeholder to facilitate future property lookups
            self.providePlaceholder(at: url, completionHandler: { error in
                // TODO: handle any error, do any necessary cleanup
            })
        }
    }
    
    // MARK: - Actions
    
    /* TODO: implement the actions for items here
     each of the actions follows the same pattern:
     - make a note of the change in the local model
     - schedule a server request as a background task to inform the server of the change
     - call the completion block with the modified item in its post-modification state
     */
    
    // MARK: - Enumeration
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> NSFileProviderEnumerator {
        let maybeEnumerator: NSFileProviderEnumerator?
        if (containerItemIdentifier == NSFileProviderItemIdentifier.rootContainer) {
            // TODO: instantiate an enumerator for the container root
            maybeEnumerator = FileProviderEnumerator(file: root)
        } else if (containerItemIdentifier == NSFileProviderItemIdentifier.workingSet) {
            maybeEnumerator = nil
        } else {

            // TODO: determine if the item is a directory or a file
            // - for a directory, instantiate an enumerator of its subitems
            // - for a file, instantiate an enumerator that observes changes to the file
            let file = File.file(with: containerItemIdentifier.rawValue)
            maybeEnumerator = FileProviderEnumerator(file: file!)
        }
        guard let enumerator = maybeEnumerator else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:])
        }
        return enumerator
    }
}

extension File {
    static func file(at url: URL, root: File) -> File? {
        var item = root
        let pathComponents = url.pathComponents[1...]

        compoIt: for compo in pathComponents {
            for itemChild in item.contents {
                if itemChild.url.pathComponents.last == compo {
                    item = itemChild
                    continue compoIt
                }
            }
            return nil //didn't find children, return early
        }
        return item
    }

    static func file(with identifier: String) -> File? {
        let fetchRequest : NSFetchRequest<File> = File.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "id == %@", identifier)
        let file = CoreDataHelper.viewContext.fetchSingle(fetchRequest)
        return file.value
    }
}
