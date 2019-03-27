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
    let fileSync: FileSync

    lazy var coordinator: NSFileCoordinator = {
        let result = NSFileCoordinator()
        result.purposeIdentifier = NSFileProviderManager.default.providerIdentifier
        return result
    }()

    override init() {
        guard let acc = LoginHelper.loadAccount() else {
            fatalError("No account, login in the main app first")
        }

        guard let account = LoginHelper.validate(acc) else {
            fatalError("Invalid Account, login again")
        }

        Globals.account = account

        rootDirectory = FileHelper.rootFolder
        fileSync = FileSync(backgroundSessionIdentifier: (Bundle.main.bundleIdentifier ?? "fileprovider") + ".background" )
        super.init()
    }

    deinit {
        fileSync.invalidate()
    }

    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        if identifier == .rootContainer {
            return FileProviderItem(file: rootDirectory)
        } else if identifier == .workingSet {
            throw NSFileProviderError(.noSuchItem)
        } else {
            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
            guard let file = File.by(id: identifier.rawValue, in: context) else {
                throw NSFileProviderError(.noSuchItem)
            }

            return FileProviderItem(file: file)
        }
    }

    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        // resolve the given identifier to a file on disk
        let id = identifier == .rootContainer ? FileHelper.rootDirectoryID : identifier.rawValue
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        return context.performAndWait { () -> URL? in
            let file = File.by(id: id, in: context)
            return file?.localURL
        }
    }

    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        guard let id = File.id(from: url) else { return nil }
        return NSFileProviderItemIdentifier(id)
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
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }

        let id = identifier == .rootContainer ? FileHelper.rootDirectoryID : identifier.rawValue
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        guard let file = File.by(id: id, in: context) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }

        if FileManager.default.fileExists(atPath: file.localURL.path) {
            completionHandler(nil)
        } else {
            self.fileSync.downloadSignedURL(fileId: file.id) { [unowned self] result in
                switch result {
                case .failure (let error):
                    DispatchQueue.main.async {
                        completionHandler(error)
                    }

                case .success(let signedURL):
                    let task = self.fileSync.download(id: "filedownload__\(identifier.rawValue)",
                                                      at: signedURL.url,
                                                      moveTo: url,
                                                      backgroundSession: true) { result in
                            DispatchQueue.main.async {
                                completionHandler(result.error)
                            }
                    }

                    NSFileProviderManager.default.register(task, forItemWithIdentifier: identifier) { _ in }
                    task.resume()
                }
            }?.resume()
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
        var maybeEnumerator: NSFileProviderEnumerator?
        if containerItemIdentifier == NSFileProviderItemIdentifier.rootContainer {
            maybeEnumerator = FolderEnumerator(item: containerItemIdentifier)
        } else if containerItemIdentifier == NSFileProviderItemIdentifier.workingSet {

            let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
            fetchRequest.predicate = FileHelper.workingSetPredicate

            let fetchResult = CoreDataHelper.viewContext.fetchMultiple(fetchRequest)
            guard let result = fetchResult.value else {
                fatalError(fetchResult.error?.localizedDescription ?? "")
            }

            maybeEnumerator = WorkingSetEnumerator(workingSet: result)
        } else {
            let item = try self.item(for: containerItemIdentifier) as! FileProviderItem
            let id = item.itemIdentifier == .rootContainer ? FileHelper.rootDirectoryID : item.itemIdentifier.rawValue
            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
            guard let file = File.by(id: id, in: context) else {
                fatalError("Can't create enumerator with id: \(id)")
            }

            if file.isDirectory {
                maybeEnumerator = OnlineFolderEnumerator(itemIdentifier: containerItemIdentifier, fileSync: self.fileSync)
            } else {
                maybeEnumerator = FileEnumerator(file: file)
            }
        }

        guard let enumerator = maybeEnumerator else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo: [:])
        }

        return enumerator
    }

    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier],
                                  requestedSize size: CGSize,
                                  perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void,
                                  completionHandler: @escaping (Error?) -> Void) -> Progress {

        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        progress.isCancellable = true
        progress.cancellationHandler = {}

        let ids = itemIdentifiers.map { $0.rawValue }
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        guard let files = File.with(ids: ids, in: context) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            progress.becomeCurrent(withPendingUnitCount: Int64(itemIdentifiers.count))
            return progress
        }

        for file in files {
            let itemIdentifier = FileProviderItem(file: file).itemIdentifier
            if file.thumbnailRemoteURL == nil {
                perThumbnailCompletionHandler(itemIdentifier, nil, nil)
                progress.completedUnitCount += 1
                continue
            }

            if FileManager.default.fileExists(atPath: file.localThumbnailURL.path) {
                do {
                    let data = try Data(contentsOf: file.localThumbnailURL, options: .alwaysMapped)
                    perThumbnailCompletionHandler(itemIdentifier, data, nil)
                } catch let error {
                    perThumbnailCompletionHandler(itemIdentifier, nil, error)
                }

                progress.completedUnitCount += 1
                continue
            }

            let task = fileSync.downloadThumbnail(from: file, background: true) { result in
                guard !progress.isCancelled else {
                    return
                }

                guard let fileURL = result.value else {
                    DispatchQueue.main.async {
                        perThumbnailCompletionHandler(itemIdentifier, nil, result.error!)
                    }

                    return
                }

                let data = try? Data(contentsOf: fileURL, options: .alwaysMapped)
                DispatchQueue.main.async {
                    perThumbnailCompletionHandler(itemIdentifier, data, nil)
                }

                if progress.isFinished {
                    completionHandler(nil)
                }
            }

            if let task = task {
                progress.addChild(task.progress, withPendingUnitCount: 1)
                task.resume()
            } else {
                progress.completedUnitCount += 1
            }
        }

        return progress
    }

    override func setTagData(_ tagData: Data?,
                             forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier,
                             completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        let id = itemIdentifier == .rootContainer ? FileHelper.rootDirectoryID : itemIdentifier.rawValue

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        let providerItem = context.performAndWait { () -> FileProviderItem in
            let file = File.by(id: id, in: context)!
            file.localTagData = tagData

            let workingSetAnchor = context.fetchSingle(WorkingSetSyncAnchor.mainAnchorFetchRequest).value!
            workingSetAnchor.value += 1

            _ = context.saveWithResult()
            return FileProviderItem(file: file)
        }

        completionHandler(providerItem, nil)
        NSFileProviderManager.default.signalEnumerator(for: .workingSet) { _ in }
    }

    override func setFavoriteRank(_ favoriteRank: NSNumber?,
                                  forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier,
                                  completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        let id = itemIdentifier == .rootContainer ? FileHelper.rootDirectoryID : itemIdentifier.rawValue

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        let providerItem = context.performAndWait { () -> FileProviderItem in
            let rankValueData: Data?
            if let favoriteRank = favoriteRank {
                var rankValue = favoriteRank.uint64Value
                rankValueData = Data(buffer: UnsafeBufferPointer(start: &rankValue, count: 1))
            } else {
                rankValueData = nil
            }

            let file = File.by(id: id, in: context)!
            file.favoriteRankData = rankValueData

            let workingSetAnchor = context.fetchSingle(WorkingSetSyncAnchor.mainAnchorFetchRequest).value!
            workingSetAnchor.value += 1

            _ = context.saveWithResult()
            return FileProviderItem(file: file)
        }

        completionHandler(providerItem, nil)
        NSFileProviderManager.default.signalEnumerator(for: .workingSet) { _ in }
    }

    override func setLastUsedDate(_ lastUsedDate: Date?,
                                  forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier,
                                  completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        let id = itemIdentifier == .rootContainer ? FileHelper.rootDirectoryID : itemIdentifier.rawValue

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        let providerItem = context.performAndWait { () -> FileProviderItem in
            let file = File.by(id: id, in: context)!
            file.lastReadAt = lastUsedDate!

            let workingSetAnchor = context.fetchSingle(WorkingSetSyncAnchor.mainAnchorFetchRequest).value!
            workingSetAnchor.value += 1

            _ = context.saveWithResult()
            return FileProviderItem(file: file)
        }

        completionHandler(providerItem, nil)
        NSFileProviderManager.default.signalEnumerator(for: .workingSet) { _ in }
    }
}
