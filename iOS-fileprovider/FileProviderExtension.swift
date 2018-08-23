//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import CoreData
import FileProvider

class FileProviderExtension: NSFileProviderExtension {
    
    let rootDirectory: File
    var currentDirectory: File
    let fileSync = FileSync()
    
    override init() {
        guard let acc = LoginHelper.loadAccount() else {
            fatalError("No account, login in the main app first")
        }

        guard let account = LoginHelper.validate(acc) else {
            fatalError("Invalid Account, login again")
        }

        Globals.account = account

        rootDirectory = FileHelper.rootFolder
        currentDirectory = rootDirectory
        super.init()
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        if identifier == .rootContainer {
            return rootDirectory
        } else if identifier == .workingSet {
            throw NSFileProviderError(.noSuchItem)
        } else {
            let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", identifier.rawValue)

            let result = CoreDataHelper.viewContext.fetchSingle(fetchRequest)
            if let file = result.value {
                return file
            }
            throw NSFileProviderError(.noSuchItem)
        }
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        // resolve the given identifier to a file on disk
        guard let file = (try? item(for: identifier)) as? File else {
            return nil
        }
        return file.localURL
    }
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        // resolve the given URL to a persistent identifier using a database
        // Filename of format fileid__name, extract id from filename, no need to hit the DB
        let filename = url.lastPathComponent
        guard let localURLSeparatorRange = filename.range(of: "__") else {
            return nil
        }
        let fileIdentifier = String(filename[filename.startIndex..<localURLSeparatorRange.lowerBound])
        return NSFileProviderItemIdentifier(fileIdentifier)
    }
    
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }

        do {
            let fileProviderItem = try item(for: identifier)
            let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
            try NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: fileProviderItem)
            completionHandler(nil)
        } catch let error {
            completionHandler(error)
        }
    }

    override func startProvidingItem(at url: URL, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        // Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
        guard let identifier = persistentIdentifierForItem(at: url),
              let file = (try? item(for: identifier)) as? File else {
                completionHandler(NSFileProviderError(.noSuchItem))
                return
        }

        if FileManager.default.fileExists(atPath: url.absoluteString) {
            completionHandler(nil)
        } else {
            fileSync.download(file, background: true, progressHandler: {_ in }).onSuccess { (_) in
                completionHandler(nil)
            }.onFailure { (error) in
                completionHandler(error)
            }
        }

        /* TODO:
         This is one of the main entry points of the file provider. We need to check whether the file already exists on disk,
         whether we know of a more recent version of the file, and implement a policy for these cases. Pseudocode:
         
         if !fileOnDisk {
             downloadRemoteFile()
             callCompletion(downloadErrorOrNil)
         } else if fileIsCurrent {
             callCompletion(nil)
         } else {
             if localFileHasChanges {
                 // in this case, a version of the file is on disk, but we know of a more recent version
                 // we need to implement a strategy to resolve this conflict
                 moveLocalFileAside()
                 scheduleUploadOfLocalFile()
                 downloadRemoteFile()
                 callCompletion(downloadErrorOrNil)
             } else {
                 downloadRemoteFile()
                 callCompletion(downloadErrorOrNil)
             }
         }
         */
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
        /*
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
        */
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
        var maybeEnumerator: NSFileProviderEnumerator? = nil
        if (containerItemIdentifier == NSFileProviderItemIdentifier.rootContainer) {
            maybeEnumerator = FolderEnumerator(file: rootDirectory)
        } else if (containerItemIdentifier == NSFileProviderItemIdentifier.workingSet) {
            // TODO: instantiate an enumerator for the working set
            maybeEnumerator = WorkingSetEnumerator()
        } else {
            // TODO: determine if the item is a directory or a file
            // - for a directory, instantiate an enumerator of its subitems
            // - for a file, instantiate an enumerator that observes changes to the file

            let itemToEnumerate = try item(for: containerItemIdentifier) as! File
            if itemToEnumerate.isDirectory {
                maybeEnumerator = FolderEnumerator(file: itemToEnumerate)
            } else {
                // TODO: Replace with proper file observing enumerator
                maybeEnumerator = FolderEnumerator(file: itemToEnumerate)
            }
        }
        guard let enumerator = maybeEnumerator else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:])
        }
        return enumerator
    }

    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier],
                                  requestedSize size: CGSize,
                                  perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void,
                                  completionHandler: @escaping (Error?) -> Void) -> Progress {

        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))

        let files = itemIdentifiers.map { try! item(for: $0) as! File }

        var downloadTasks = [Future<URL, SCError>]()

        for file in files {
            let itemIdentifier = file.itemIdentifier
            guard file.thumbnailRemoteURL != nil else {
                perThumbnailCompletionHandler(itemIdentifier, nil, nil)
                progress.completedUnitCount += 1
                continue
            }

            let future = FileSync.default.downloadThumbnail(from: file, background: true, progressHandler: { _ in }).onSuccess { url in
                let data = try? Data(contentsOf: url, options: .alwaysMapped)
                DispatchQueue.main.async {
                    perThumbnailCompletionHandler(itemIdentifier, data, nil)
                }
            }.onFailure { error in
                DispatchQueue.main.async {
                    perThumbnailCompletionHandler(itemIdentifier, nil, error)
                }
            }.onComplete { _ in
                progress.completedUnitCount += 1
            }

            downloadTasks.append(future)
        }

        downloadTasks.sequence().onSuccess { _ in
            completionHandler(nil)
        }.onFailure { error in
            completionHandler(error)
        }

        return progress
    }
}
