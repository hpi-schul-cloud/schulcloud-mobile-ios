//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import Foundation
import Marshal

public class FileHelper {
    public static var rootDirectoryID = "root"
    public static var coursesDirectoryID = "courses"
    public static var sharedDirectoryID = "shared"
    public static var userDirectoryID: String {
        return "users/\(Globals.account?.userId ?? "")/"
    }

    private static var notSynchronizedPath: [String] = {
        return [rootDirectoryID]
    }()

    fileprivate static var userDataRootURL: URL {
        let userId = Globals.account?.userId ?? "0"
        let url = URL(string: "users")!
        return url.appendingPathComponent(userId, isDirectory: true)
    }

    public static var rootFolder: File {
        return fetchRootFolder() ?? createBaseStructure()
    }

    fileprivate static func fetchRootFolder() -> File? {
        let fetchRequest = NSFetchRequest(entityName: "File") as NSFetchRequest<File>
        fetchRequest.predicate = NSPredicate(format: "id == %@", rootDirectoryID)

        let result = CoreDataHelper.viewContext.fetchSingle(fetchRequest)
        if case let .success(file) = result {
            return file
        } else {
            return nil
        }
    }

    /// Create the basic folder structure and return main Root
    fileprivate static func createBaseStructure() -> File {
        do {
            try FileManager.default.createDirectory(at: File.localContainerURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: File.thumbnailContainerURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Can't create local file container")
        }

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        context.performAndWait {
            let anchor = WorkingSetSyncAnchor(context: context)
            anchor.id = WorkingSetSyncAnchor.mainId
            anchor.value = 0
        }

        let rootFolderObjectId: NSManagedObjectID = context.performAndWait {
            let rootFolder = File.createLocal(context: context, id: rootDirectoryID, name: "Dateien", parentFolder: nil, isDirectory: true)

            File.createLocal(context: context,
                             id: userDirectoryID,
                             name: "Meine Dateien",
                             parentFolder: rootFolder,
                             isDirectory: true,
                             remoteURL: URL(string: userDirectoryID) )
            File.createLocal(context: context,
                             id: coursesDirectoryID,
                             name: "Kurs-Dateien",
                             parentFolder: rootFolder,
                             isDirectory: true)
            File.createLocal(context: context,
                             id: sharedDirectoryID,
                             name: "geteilte Dateien",
                             parentFolder: rootFolder,
                             isDirectory: true)

            if case let .failure(error) = context.saveWithResult() {
                fatalError("Unresolved error \(error)") // TODO: replace this with something more friendly
            }

            return rootFolder.objectID
        }

        return CoreDataHelper.viewContext.typedObject(with: rootFolderObjectId) as File
    }

    public static func delete(file: File) -> Future<Void, SCError> {
        struct DidSuccess: Unmarshaling { // swiftlint:disable:this nesting
            init(object: MarshaledObject) throws {
            }
        }

        var path = URL(string: "fileStorage")
        if file.isDirectory { path?.appendPathComponent("directories", isDirectory: true) }
        path?.appendPathComponent(file.id)

        let parameters: [String: Any] = ["path": file.remoteURL!.absoluteString]

        // TODO: Figure out the success structure
//        let request: Future<DidSuccess, SCError> = ApiHelper.request(path!.absoluteString,
//                                                                     method: .delete,
//                                                                     parameters: parameters,
//                                                                     encoding: JSONEncoding.default).deserialize(keyPath: "").asVoid()
        fatalError("Implement deleting files")
    }

    public static func updateDatabase(contentsOf parentFolder: File, using contents: [String: Any]) -> Future<[File], SCError> {
        let promise = Promise<[File], SCError>()
        let parentFolderObjectId = parentFolder.objectID

        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            do {
                let files: [[String: Any]] = try contents.value(for: "files")
                let folders: [[String: Any]] = try contents.value(for: "directories")
                guard let parentFolder = context.existingTypedObject(with: parentFolderObjectId) as? File else {
                    log.error("Unable to find parent folder")
                    return
                }

                let createdFiles = try files.map {
                    try File.createOrUpdate(inContext: context, parentFolder: parentFolder, isDirectory: false, data: $0)
                }

                let createdFolders = try folders.map {
                    try File.createOrUpdate(inContext: context, parentFolder: parentFolder, isDirectory: true, data: $0)
                }

                // remove deleted files or folders
                let currentItemsIDs: [String] =  createdFiles.map { $0.id } + createdFolders.map { $0.id }
                let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
                let notOnServerPredicate = NSPredicate(format: "NOT (id IN %@)", currentItemsIDs)
                let isDownloadedPredicate = NSPredicate(format: "downloadStateValue == \(File.DownloadState.downloaded.rawValue)")

                let locallyCachedFiles = NSFetchRequest<File>(entityName: "File")
                locallyCachedFiles.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notOnServerPredicate,
                                                                                                   parentFolderPredicate,
                                                                                                   isDownloadedPredicate, ])

                let coordinator = NSFileCoordinator()
                let deletedFilesWithLocalCache = context.fetchMultiple(locallyCachedFiles).value ?? []
                for file in deletedFilesWithLocalCache {
                    var error: NSError?
                    coordinator.coordinate(writingItemAt: file.localURL, options: .forDeleting, error: &error) { url in
                        try? FileManager.default.removeItem(at: url)
                    }
                }

                let deletedFileFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "File")
                deletedFileFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notOnServerPredicate, parentFolderPredicate])
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: deletedFileFetchRequest)
                try context.execute(deleteRequest)

                try context.save()
                // TODO(FileProvider): Signal changes in the parent folder here
                promise.success(createdFiles + createdFolders)
            } catch let error as MarshalError {
                promise.failure(.jsonDeserialization(error.localizedDescription))
            } catch let error {
                log.error(error)
                promise.failure(.coreData(error))
            }
        }

        return promise.future
    }
}

// MARK: Course folder structure management
extension FileHelper {
    public static func processCourseUpdates(changes: [String: [(id: String, name: String)]]) {
        let objectID = FileHelper.rootFolder.contents.first { $0.id == FileHelper.coursesDirectoryID }!.objectID

        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            guard let parentFolder = context.typedObject(with: objectID) as? File else {
                    log.error("Unable to find course directory")
                    return
            }

            if let deletedCourses = changes[NSDeletedObjectsKey], !deletedCourses.isEmpty {
                for (courseId, _) in deletedCourses {
                    guard let content = parentFolder.contents.first(where: { $0.id == courseId }) else { continue }
                    parentFolder.contents.remove(content)
                }
            }

            if let updatedCourses = changes[NSUpdatedObjectsKey], !updatedCourses.isEmpty {
                for (courseId, courseName) in updatedCourses {
                    if let file = parentFolder.contents.first(where: { $0.id == courseId }) {
                        file.name = courseName
                    } else {
                        File.createLocal(context: context,
                                         id: courseId,
                                         name: courseName,
                                         parentFolder: parentFolder,
                                         isDirectory: true,
                                         remoteURL: URL(string: "courses/\(courseId)/") )
                    }
                }
            }

            if let insertedCourses = changes[NSInsertedObjectsKey], !insertedCourses.isEmpty {
                for (courseId, courseName) in insertedCourses {
                    File.createLocal(context: context,
                                     id: courseId,
                                     name: courseName,
                                     parentFolder: parentFolder,
                                     isDirectory: true,
                                     remoteURL: URL(string: "courses/\(courseId)/") )
                }
            }

            _ = context.saveWithResult()
        }
    }
}

extension FileHelper {
    public static var workingSetPredicate: NSPredicate {
        let todayCompo = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let today = Calendar.current.date(from: todayCompo)
        var twoWeeksAgoCompo = DateComponents()
        twoWeeksAgoCompo.weekOfYear = -2

        let twoWeeksAgo = Calendar.current.date(byAdding: twoWeeksAgoCompo, to: today!)!

        let lastReadPred = NSPredicate(format: "lastReadAt >= %@", twoWeeksAgo as NSDate)
        let favoriteRankPredicate = NSPredicate(format: "favoriteRankData != nil")
        let tagDataPredicate = NSPredicate(format: "localTagData != nil")

        return NSCompoundPredicate(orPredicateWithSubpredicates: [lastReadPred, favoriteRankPredicate, tagDataPredicate])
    }
}
