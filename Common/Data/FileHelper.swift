//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Alamofire
import BrightFutures
import CoreData
import Foundation
import Marshal

public class FileSync: NSObject {

    static public var `default`: FileSync = FileSync()

    public typealias ProgressHandler = (Float) -> Void

    fileprivate var backgroundSession: URLSession!
    fileprivate var foregroundSession: URLSession!
    fileprivate let metadataSession: URLSession

    var runningTask: [Int: Promise<URL, SCError>] = [:]
    var progressHandlers: [Int: ProgressHandler] = [:]

    public override init() {
        metadataSession = URLSession(configuration: URLSessionConfiguration.default)

        super.init()

        let configuration = URLSessionConfiguration.background(withIdentifier: "org.schulcloud.file.background")
        backgroundSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        foregroundSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }

    deinit {
        backgroundSession.finishTasksAndInvalidate()
        metadataSession.invalidateAndCancel()
        foregroundSession.invalidateAndCancel()
    }

    // MARK: Request building helper
    private var fileStorageURL: URL {
        return Brand.default.servers.backend.appendingPathComponent("fileStorage")
    }

    private func getQueryURL(for file: File) -> URL? {
        guard let remoteURL = file.remoteURL else { return nil }

        var urlComponent = URLComponents(url: fileStorageURL, resolvingAgainstBaseURL: false)!
        urlComponent.query = "path=\(remoteURL.absoluteString.removingPercentEncoding!)"
        return try? urlComponent.asURL()
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        return request
    }

    private func confirmNetworkResponse(data: Data?, response: URLResponse?, error: Error?) throws -> Data {
        guard error == nil else {
            throw SCError.network(error)
        }

        guard let response = response as? HTTPURLResponse,
            200 ... 299 ~= response.statusCode else {
                throw SCError.network(nil)
        }

        guard let data = data else {
            throw SCError.network(nil)
        }

        return data
    }

    // MARK: Directory download management

    public func updateContent(of directory: File) -> Future<Void, SCError> {
        guard FileHelper.rootDirectoryID != directory.id else {
            return Future(error: SCError.unknown)
        }

        switch directory.id {
        case FileHelper.coursesDirectoryID:
            return CourseHelper.syncCourses().asVoid()

        case FileHelper.sharedDirectoryID:
            return self.downloadSharedFiles().flatMap { objects -> Future<Void, SCError> in
                var updates: [Future<Void, SCError>] = []
                for json in objects {
                    updates.append(FileHelper.updateDatabase(contentsOf: directory, using: json))
                }

                return updates.sequence().asVoid()
            }.asVoid()
        default:
            return self.downloadContent(of: directory).flatMap { json -> Future<Void, SCError> in
                return FileHelper.updateDatabase(contentsOf: directory, using: json)
            }.asVoid()
        }
    }

    fileprivate func downloadContent(of directory: File) -> Future<[String: Any], SCError> {
        guard directory.isDirectory else { return Future(error: .other("only works on directory") ) }

        let request = self.request(for: getQueryURL(for: directory)! )
        let promise: Promise<[String: Any], SCError> = Promise()
        metadataSession.dataTask(with: request) { data, response, error in
            var responseData: Data
            do {
                responseData = try self.confirmNetworkResponse(data: data, response: response, error: error)
            } catch let error as SCError {
                promise.failure(error)
                return
            } catch {
                promise.failure( .other("Weird"))
                return
            }

            guard let json = (try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments)) as? [String: Any] else {
                promise.failure(SCError.jsonDeserialization("Can't deserialize"))
                return
            }

            promise.success(json)
        }.resume()
        return promise.future
    }

    public func downloadSharedFiles() -> Future<[[String: Any]], SCError> {
        let promise = Promise<[[String: Any]], SCError>()

        let request = self.request(for: Brand.default.servers.backend.appendingPathComponent("files") )
        metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! MarshaledObject
                let files: [MarshaledObject] = try json.value(for: "data")
                let sharedFiles = files.filter { object -> Bool in
                    return (try? object.value(for: "context")) == "geteilte Datei"
                }

                promise.success(sharedFiles as! [[String: Any]])
            } catch let error as SCError {
                promise.failure(error)
            } catch let error {
                promise.failure(.jsonDeserialization(error.localizedDescription) )
            }
        }.resume()
        return promise.future
    }

    // MARK: File materialization
    public func download(_ file: File,
                         background: Bool = false,
                         onDownloadInitialised: @escaping () -> Void,
                         progressHandler: @escaping ProgressHandler ) -> Future<URL, SCError> {
        let localURL = file.localURL
        let downloadSession: URLSession = background ? self.backgroundSession : self.foregroundSession
        guard [File.DownloadState.notDownloaded, File.DownloadState.downloadFailed].contains(file.downloadState) else {
            return Future<URL, SCError>(value: localURL)
        }

        file.downloadState = .downloading
        return signedURL(for: file).flatMap { url -> Future<URL, SCError> in
            onDownloadInitialised()
            return self.download(signedURL: url, moveTo: localURL, downloadSession: downloadSession, progressHandler: progressHandler)
        }
    }

    fileprivate func signedURL(for file: File) -> Future<URL, SCError> {
        guard !file.isDirectory else { return Future(error: .other("Can't download folder") ) }

        var request = self.request(for: fileStorageURL.appendingPathComponent("signedUrl") )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: Any = [
            "path": file.remoteURL!.absoluteString.removingPercentEncoding!,
            //            "fileType": mime.lookup(file),
            "action": "getObject",
            ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

        let promise = Promise<URL, SCError>()
        metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let signedURL: URL = try (json as! MarshaledObject).value(for: "url")
                promise.success(signedURL)
            } catch let error as SCError {
                promise.failure(error)
            } catch let error {
                promise.failure(.jsonDeserialization(error.localizedDescription) )
            }
        }.resume()
        return promise.future
    }

    fileprivate func download(signedURL: URL,
                              moveTo localURL: URL,
                              downloadSession: URLSession,
                              progressHandler: @escaping ProgressHandler) -> Future<URL, SCError> {
        let promise = Promise<URL, SCError>()
        let task = downloadSession.downloadTask(with: signedURL)
        task.taskDescription = localURL.absoluteString
        task.resume()
        runningTask[task.taskIdentifier] = promise
        progressHandlers[task.taskIdentifier] = progressHandler
        return promise.future
    }

}

extension FileSync: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        let promise = runningTask[downloadTask.taskIdentifier]
        do {
            let urlString = downloadTask.taskDescription!

            let localURL = URL(string: urlString)!
            try FileManager.default.moveItem(at: location, to: localURL)
            promise?.success(localURL)
        } catch let error {
            promise?.failure(.other(error.localizedDescription))
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let promise = runningTask[task.taskIdentifier]
        if let error = error {
            promise?.failure(.network(error))
        }

        runningTask.removeValue(forKey: task.taskIdentifier)
        progressHandlers.removeValue(forKey: task.taskIdentifier)
    }

    // Download progress
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        if let progressHandler = progressHandlers[downloadTask.taskIdentifier] {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            progressHandler(progress)
        }
    }
}

public class FileHelper {
    public static var rootDirectoryID = "root"
    public static var coursesDirectoryID = "courses"
    public static var sharedDirectoryID = "shared"
    public static var userDirectoryID: String {
        return "users/\(Globals.account?.userId ?? "")"
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
        } catch {
            fatalError("Can't create local file container")
        }

        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        let rootFolderObjectId: NSManagedObjectID = context.performAndWait {
            let rootFolder = File.createLocal(context: context, id: rootDirectoryID, name: "Dateien", parentFolder: nil, isDirectory: true)

            File.createLocal(context: context, id: userDirectoryID, name: "Meine Dateien", parentFolder: rootFolder, isDirectory: true, remoteURL: userDirectoryID)
            File.createLocal(context: context, id: coursesDirectoryID, name: "Kurs-Dateien", parentFolder: rootFolder, isDirectory: true)
            File.createLocal(context: context, id: sharedDirectoryID, name: "geteilte Dateien", parentFolder: rootFolder, isDirectory: true)

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

        let parameters: Parameters = ["path": file.remoteURL!.absoluteString]

        // TODO: Figure out the success structure
//        let request: Future<DidSuccess, SCError> = ApiHelper.request(path!.absoluteString,
//                                                                     method: .delete,
//                                                                     parameters: parameters,
//                                                                     encoding: JSONEncoding.default).deserialize(keyPath: "").asVoid()
        fatalError("Implement deleting files")
    }

    public static func updateDatabase(contentsOf parentFolder: File, using contents: [String: Any]) -> Future<Void, SCError> {
        let promise = Promise<Void, SCError>()
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
                let isDownloadedPredicate = NSPredicate(format: "downloadState_ == \(File.DownloadState.downloaded.rawValue)")

                let locallyCachedFiles = NSFetchRequest<File>(entityName: "File")
                locallyCachedFiles.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notOnServerPredicate,
                                                                                                   parentFolderPredicate,
                                                                                                   isDownloadedPredicate, ])

                let coordinator = NSFileCoordinator()
                let deletedFilesWithLocalCache = context.fetchMultiple(locallyCachedFiles).value ?? []
                for file in deletedFilesWithLocalCache {
                    var error: NSError? = nil
                    coordinator.coordinate(writingItemAt: file.localURL, options: .forDeleting, error: &error) { url in
                        do {
                            try FileManager.default.removeItem(at: url)
                        } catch {
                            fatalError()
                        }
                    }
                }

                let deletedFileFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "File")
                deletedFileFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notOnServerPredicate, parentFolderPredicate])
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: deletedFileFetchRequest)
                try context.execute(deleteRequest)

                try context.save()
                // TODO(FileProvider): Signal changes in the parent folder here
                promise.success(())
            } catch let error as MarshalError {
                promise.failure(.jsonDeserialization(error.localizedDescription))
            } catch let error {
                log.error(error)
                promise.failure(.database(error.localizedDescription))
            }
        }

        return promise.future
    }
}

// MARK: Course folder structure management
extension FileHelper {
    public static func processCourseUpdates(changes: [String: [(id: String, name: String)]]) {
        let rootObjectId = FileHelper.rootFolder.objectID

        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            guard let rootFolder = context.existingTypedObject(with: rootObjectId) as? File,
                let parentFolder = rootFolder.contents.first(where: { $0.id == FileHelper.coursesDirectoryID }) else {
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
                                         remoteURL: "courses/\(courseId)/")
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
                                     remoteURL: "courses/\(courseId)/")
                }
            }

            _ = context.saveWithResult()
        }
    }
}
