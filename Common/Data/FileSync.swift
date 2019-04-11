//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import CoreServices
import Foundation
import Marshal

public struct SignedURLInfo {
    public let url: URL
    public let header: [HeaderKeys: String]

    public enum HeaderKeys: String {
        case path = "x-amz-meta-path"
        case name = "x-amz-meta-name"
        case flatName = "x-amz-meta-flat-name"
        case thumbnail = "x-amz-meta-thumbnail"
        case type = "Content-Type"
    }
}

public class FileSync: NSObject {

    static public var `default`: FileSync = {
        let identifier = (Bundle.main.bundleIdentifier ?? "") + ".background"
        return FileSync(backgroundSessionIdentifier: identifier)
    }()

    public typealias ProgressHandler = (Float) -> Void
    public typealias FileDownloadHandler = (Result<URL, SCError>) -> Void
    public typealias FileUploadHandler = (Result<Void, SCError>) -> Void

    public enum FileTransferCompletionType {
        case downloadHandler(FileDownloadHandler)
        case uploadHandler(FileUploadHandler)

        func error(_ error: SCError) {
            switch self {
            case .downloadHandler(let handler):
                handler(.failure(error))
            case .uploadHandler(let handler):
                handler(.failure(error))
            }
        }
    }

    private var backgroundSession: URLSession!
    private var foregroundSession: URLSession!
    private let metadataSession: URLSession

    private struct FileTransferInfo {
        let task: URLSessionTask
        let completionHandler: FileTransferCompletionType
        let localFileURL: URL
    }

    private var runningTask: [String: FileTransferInfo] = [:]

    public init(backgroundSessionIdentifier: String) {
        metadataSession = URLSession(configuration: URLSessionConfiguration.default)

        super.init()

        let backgroudConfiguration = URLSessionConfiguration.background(withIdentifier: backgroundSessionIdentifier)
        backgroudConfiguration.sharedContainerIdentifier = Bundle.main.appGroupIdentifier
        backgroundSession = URLSession(configuration: backgroudConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        foregroundSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }

    public func invalidate() {
        self.backgroundSession.finishTasksAndInvalidate()
        self.metadataSession.invalidateAndCancel()
        self.foregroundSession.invalidateAndCancel()
    }

    // MARK: Request building helper
    private var fileStorageURL: URL {
        return Brand.default.servers.backend.appendingPathComponent("fileStorage")
    }

    private func getQueryURL(for file: File) -> URL? {
        var urlComponent = URLComponents(url: fileStorageURL, resolvingAgainstBaseURL: false)!
        var queryItem = [URLQueryItem(name: "owner", value: file.ownerId)]
        if file.parentDirectory!.id != FileHelper.rootDirectoryID,
           file.parentDirectory!.id != FileHelper.coursesDirectoryID {
            queryItem.append(URLQueryItem(name: "parent", value: file.id))
        }
        urlComponent.queryItems = queryItem
        return urlComponent.url
    }

    private func authenticatedURLRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        return request
    }

    private func GETRequest(for url: URL) -> URLRequest {
        var request = authenticatedURLRequest(for: url)
        request.httpMethod = "GET"
        return request
    }

    private func POSTRequest(for url: URL) -> URLRequest {
        var request = authenticatedURLRequest(for: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        return request
    }

    private func DELETERequest(for url: URL) -> URLRequest {
        var request = authenticatedURLRequest(for: url)
        request.httpMethod = "DELETE"
        return request
    }

    private func PUTRequest(for url: URL) -> URLRequest {
        var request = authenticatedURLRequest(for: url)
        request.httpMethod = "PUT"
        return request
    }

    private func PATCHRequest(for url: URL) -> URLRequest {
        var request = authenticatedURLRequest(for: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PATCH"
        return request
    }

    private func confirmNetworkResponse(data datao: Data?, response responseo: URLResponse?, error erroro: Error?) throws -> Data {
        guard let response = responseo as? HTTPURLResponse else {
            throw SCError.network(erroro)
        }

        guard 200 ... 299 ~= response.statusCode else {
            throw SCError.apiError(response.statusCode, "API ERROR")
        }

        guard let data = datao else {
            throw SCError.network(nil)
        }

        return data
    }

    // MARK: Directory download management

    public func updateContent(of directory: File, completionBlock: @escaping (Result<[File], SCError>) -> Void) -> URLSessionTask? {
        guard FileHelper.rootDirectoryID != directory.id else {
            completionBlock(.success( Array(directory.contents)))
            return nil
        }

        let taskCompletionBlock: (Result<[[String: Any]], SCError>) -> Void = { result in
            completionBlock(result.flatMap {
                FileHelper.updateDatabase(contentsOf: directory, using: $0)
            })
        }

        switch directory.id {
        case FileHelper.coursesDirectoryID:
            CourseHelper.syncCourses().flatMap { _ -> Future<[File], SCError> in
                let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
                fetchRequest.predicate = NSPredicate(format: "parentDirectory.id == %@", FileHelper.coursesDirectoryID)

                let result = CoreDataHelper.viewContext.fetchMultiple(fetchRequest)
                return Future(result: result)
            }.onComplete { completionBlock($0) }
            return nil
        case FileHelper.sharedDirectoryID:
            return self.downloadSharedFiles(completionBlock: taskCompletionBlock)
        default:
            return self.downloadContent(of: directory, completionBlock: taskCompletionBlock)
        }
    }

    private func downloadContent(of directory: File, completionBlock: @escaping (Result<[[String: Any]], SCError>) -> Void) -> URLSessionTask? {
        guard directory.isDirectory else {
            completionBlock(.failure( SCError.other("only works on directory")))
            return nil
        }

        guard let queryURL = self.getQueryURL(for: directory) else {
            completionBlock(.failure( SCError.other("no remote URL")))
            return nil
        }

        let request = self.GETRequest(for: queryURL)
        return self.metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let parsedData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                    throw SCError.jsonDeserialization("Does not result in expected JSON")
                }

                guard let json = parsedData as? [[String: Any]] else {
                    throw SCError.jsonDeserialization("Does not result in expected JSON")
                }

                completionBlock(.success(json))
            } catch let error as SCError {
                completionBlock(.failure(error))
            } catch let error {
                completionBlock(.failure(SCError.other(error.localizedDescription)))
            }
        }
    }

    public func downloadSharedFiles(completionBlock: @escaping (Result<[[String: Any]], SCError>) -> Void) -> URLSessionTask {

        let request = self.GETRequest(for: Brand.default.servers.backend.appendingPathComponent("files") )
        return metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? MarshaledObject else {
                    throw SCError.jsonDeserialization("Unexpected JSON result.")
                }

                let files: [MarshaledObject] = try json.value(for: "data")
                let sharedFiles = files.filter { object -> Bool in
                    return (try? object.value(for: "context")) == "geteilte Datei"
                } as! [[String: Any]]

                completionBlock(.success(sharedFiles))
            } catch SCError.apiError(401, let message) {
                SyncHelper.authenticationChallengerHandler?()
                completionBlock(.failure(.apiError(401, message)))
            } catch let error as SCError {
                completionBlock(.failure(error))
            } catch let error {
                completionBlock(.failure(SCError.jsonDeserialization(error.localizedDescription)))
            }
        }
    }

    // MARK: File materialization
    public func uploadSignedURL(filename: String, mimeType: String, parentId: String?, completionHandler: @escaping (Result<SignedURLInfo, SCError>) -> Void) -> URLSessionTask? {
        var request = self.authenticatedURLRequest(for: fileStorageURL.appendingPathComponent("signedUrl") )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var parameters: [String: Any] = [
            "filename": filename,
            "fileType": mimeType,
        ]

        if let parentId = parentId,
            parentId != FileHelper.rootDirectoryID,
            parentId != FileHelper.userDirectoryID,
            parentId != FileHelper.sharedDirectoryID,
            parentId != FileHelper.coursesDirectoryID {
            parameters["parent"] = parentId
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            completionHandler(.failure(.jsonSerialization("Can't serialize json for SignedURL")))
            return nil
        }

        request.httpBody = jsonData

        return metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? MarshaledObject else {
                    throw SCError.jsonDeserialization("Unexpected JSON Type")
                }

                let signedURL: URL = try json.value(for: "url")
                let signedURLHeader: [String: String] = try json.value(for: "header")
                var headers = [SignedURLInfo.HeaderKeys: String]()
                for (key, value) in signedURLHeader {
                    guard let header_key = SignedURLInfo.HeaderKeys(rawValue: key) else {
                        fatalError()
                    }
                    headers[header_key] = value
                }
                let signedURLInfo = SignedURLInfo(url: signedURL, header: headers)
                completionHandler(.success( signedURLInfo))
            } catch SCError.apiError(401, let message) {
                SyncHelper.authenticationChallengerHandler?()
                completionHandler(.failure(.apiError(401, message)))
            } catch let error as SCError {
                completionHandler(.failure( error))
            } catch let error {
                completionHandler(.failure( SCError.jsonDeserialization(error.localizedDescription)))
            }
        }
    }

    // TODO: split this into specialized upload/download signedURL function, or request building at leasts
    public func downloadSignedURL(fileId: String, completionHandler: @escaping (Result<URL, SCError>) -> Void) -> URLSessionTask? {

        var component = URLComponents(url: fileStorageURL.appendingPathComponent("signedUrl"), resolvingAgainstBaseURL: false)!
        component.queryItems = [URLQueryItem(name: "file", value: fileId)]

        var request = self.authenticatedURLRequest(for: component.url!)
        request.httpMethod = "GET"

        return metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? MarshaledObject else {
                    throw SCError.jsonDeserialization("Unexpected JSON Type")
                }

                let signedURL: URL = try json.value(for: "url")
                completionHandler(.success(signedURL))
            } catch SCError.apiError(401, let message) {
                SyncHelper.authenticationChallengerHandler?()
                completionHandler(.failure(.apiError(401, message)))
            } catch let error as SCError {
                completionHandler(.failure( error))
            } catch let error {
                completionHandler(.failure( SCError.jsonDeserialization(error.localizedDescription)))
            }
        }
    }

    public func downloadThumbnail(from file: File,
                                  background: Bool = false,
                                  completionHandler: @escaping FileDownloadHandler) -> URLSessionTask? {
        guard !FileManager.default.fileExists(atPath: file.localThumbnailURL.path) else {
            completionHandler(.success( file.localThumbnailURL))
            return nil
        }

        guard let url = file.thumbnailRemoteURL else {
            completionHandler(.failure( SCError.other("No thumbnail to download")))
            return nil
        }

        return self.download(id: "thumbnail__\(file.id)",
            at: url,
            moveTo: file.localThumbnailURL,
            backgroundSession: background,
            completionHandler: completionHandler)
    }

    public func download(id: String,
                         at remoteURL: URL,
                         moveTo localURL: URL,
                         backgroundSession: Bool,
                         completionHandler: @escaping FileDownloadHandler) -> URLSessionTask {

        if let task = runningTask[id]?.task {
            return task
        }

        let downloadSession = backgroundSession ? self.backgroundSession!: self.foregroundSession!
        let task = downloadSession.downloadTask(with: remoteURL)
        task.taskDescription = id

        runningTask[id] = FileTransferInfo(task: task, completionHandler: .downloadHandler(completionHandler), localFileURL: localURL)

        return task
    }

    public func upload(id: String,
                       remoteURL: URL,
                       fileToUploadURL: URL,
                       mimeType: String,
                       completionHandler: @escaping (Result<Void, SCError>) -> Void) -> URLSessionTask {
        if let task = runningTask[id]?.task {
            return task
        }

        var urlRequest = self.PUTRequest(for: remoteURL)
        urlRequest.addValue(mimeType, forHTTPHeaderField: "Content-Type")
        let task = backgroundSession.uploadTask(with: urlRequest, fromFile: fileToUploadURL)
        task.taskDescription = id

        runningTask[id] = FileTransferInfo(task: task, completionHandler: .uploadHandler(completionHandler), localFileURL: remoteURL)
        return task
    }

    public func task(id: String) -> URLSessionTask? {
        return runningTask[id]?.task
    }

    public func createFileMetadata(name: String,
                                   mimeType: String,
                                   size: Int,
                                   flatName: String,
                                   owner: File.Owner?,
                                   parentId: String?,
                                   completionHandler: @escaping (Result<[String: Any], SCError>) -> Void) -> URLSessionTask? {

        var parameters: [String: Any] = [
            "name": name,
            "type": mimeType,
            "size": size,
            "storageFileName": flatName,
            "studentCanEdit": false,
        ]
        if let parent = parentId {
            parameters["parent"] = parent
        }

        if let owner = owner {
            switch owner {
            case .course(let id):
                parameters["owner"] = id
                parameters["refOwnerModel"] = "course"
            case .team:
                fatalError("Unsupported feature")
            case .user:
                break
            }
        }

        guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            completionHandler(.failure(SCError.jsonSerialization("Can't serialize file metadata")))
            return nil
        }

        var request = self.POSTRequest(for: fileStorageURL)
        request.httpBody = data
        return self.metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    throw SCError.jsonDeserialization("Object can't be marshaled")
                }

                completionHandler(.success(json))
            } catch let error as SCError {
                completionHandler(.failure(error))
            } catch let error {
                completionHandler(.failure(SCError.other(error.localizedDescription)))
            }
        }
    }

    public func createDirectory(name: String, ownerId: String, parentId: String?,
                       completionHandler: @escaping (Result<[String: Any], SCError>) -> Void) -> URLSessionTask? {

        fatalError("Change implementation")
        var request = self.POSTRequest(for: fileStorageURL.appendingPathComponent("directories") )

        let parameters: [String: Any] = [
            "name": name,
            "owner": ownerId,
            "parent": parentId ?? "",
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            completionHandler( .failure(.jsonSerialization("Failed serielizing json")))
            return nil
        }

        request.httpBody = jsonData
        return self.metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    throw SCError.jsonDeserialization("Unexpected JSON Type")
                }

                completionHandler(.success(json))
            } catch let error as SCError {
                completionHandler(.failure(error))
            } catch let error {
                completionHandler(.failure(SCError.other(error.localizedDescription)))
            }
        }
    }

    public func postFile(at url: URL,
                         owner: File.Owner?,
                         parentId: String?,
                         completionHandler: @escaping (Result<File, SCError>) -> Void) -> Progress {

        var flatname: String = ""
        let name = url.lastPathComponent
        let size = try! FileManager.default.attributesOfItem(atPath: url.path)[.size]! as! Int

        var type = "application/octet-stream"
        if url.pathExtension != "" {
            let pathExtension = url.pathExtension
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                    type = mimetype as String
                }
            }
        }

        let progress = Progress(totalUnitCount: 3)

        let (task, future) = self.uploadSignedURL(filename: name, mimeType: type, parentId: parentId)
        if #available(iOS 11.0, *) {
            progress.addChild(task!.progress, withPendingUnitCount: 3)
        }
        future.flatMap { signedURL -> Future<Void, SCError> in
            flatname = signedURL.header[.flatName]!

            let (task, future) = self.upload(fileAt: url, to: signedURL.url, mimeType: type)
            task.resume()
            if #available(iOS 11.0, *) {
                progress.addChild(task.progress, withPendingUnitCount: 2)
            } else {
                progress.becomeCurrent(withPendingUnitCount: 2)
            }
            return future
        }.flatMap { _ -> Future<[String: Any], SCError> in
                // Remotely create the file metadtas
            let (task, future) = self.createFileMetadata(name: name, mimeType: type, size: size, flatName: flatname, owner: owner, parentId: parentId)
            task?.resume()
            if #available(iOS 11.0, *) {
                progress.addChild(task!.progress, withPendingUnitCount: 1)
            } else {
                progress.becomeCurrent(withPendingUnitCount: 1)
            }
            return future
        }.flatMap { json -> Result<File, SCError> in
            // Create the local file metadata

            progress.becomeCurrent(withPendingUnitCount: 0)
            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
            return context.performAndWait { () -> Result<File, SCError> in
                guard let userDirectory = File.by(id: FileHelper.userDirectoryID, in: context) else {
                    return .failure(SCError.coreDataMoreThanOneObjectFound)
                }
                do {
                    let file = try File.createOrUpdate(inContext: context, parentFolder: userDirectory, data: json)
                    context.saveWithResult()
                    return .success(file)
                } catch let error as SCError {
                    return .failure(error)
                } catch let error {
                    return .failure(SCError.other(error.localizedDescription))
                }
            }
        }.onComplete(callback: completionHandler)
        task?.resume()
        return progress
    }

    private func downloadSignedURL(fileId: String) -> (URLSessionTask?, Future<URL, SCError>) {
        let promise = Promise<URL, SCError>()
        let task = self.downloadSignedURL(fileId: fileId) { promise.complete($0) }
        return (task, promise.future)
    }

    private func uploadSignedURL(filename: String, mimeType: String, parentId: String?) -> (URLSessionTask?, Future<SignedURLInfo, SCError>) {
        let promise = Promise<SignedURLInfo, SCError>()
        let task = self.uploadSignedURL(filename: filename, mimeType: mimeType, parentId: parentId) { promise.complete($0) }
        return (task, promise.future)
    }

    private func upload(fileAt url: URL, to remoteURL: URL, mimeType: String) -> (URLSessionTask, Future<Void, SCError>) {
        let promise = Promise<Void, SCError>()

        let task = self.upload(id: "upload_\(url.lastPathComponent)", remoteURL: remoteURL, fileToUploadURL: url, mimeType: mimeType) {
            promise.complete($0)
        }
        return (task, promise.future)
    }

    private func createFileMetadata(name: String, mimeType: String, size: Int, flatName: String, owner: File.Owner?, parentId: String?) -> (URLSessionTask?, Future<[String: Any], SCError>) {
        let promise = Promise<[String: Any], SCError>()
        let task = self.createFileMetadata(name: name, mimeType: mimeType, size: size, flatName: flatName, owner: owner, parentId: parentId) { promise.complete($0) }
        return (task, promise.future)
    }

    func synchronize(id: String, completionHandler: (Result<[String: Any], SCError>) -> Void) -> URLSessionTask? {
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        guard let file = File.by(id: id, in: context) else { return nil }
        let objectID = file.objectID

        let requestCompletion: (Result<[String: Any], SCError>) -> Void = { result in
            switch result {
            case .success(let json):
                let marshaled = json as MarshaledObject
                let context = CoreDataHelper.persistentContainer.newBackgroundContext()
                let parentId = context.performAndWait { () -> String in
                    let file = context.typedObject(with: objectID) as File
                    try? File.update(file: file, with: marshaled)
                    context.saveWithResult()
                    return file.parentDirectory!.id
                }

                if #available(iOS 11.0, *) {
                    NSFileProviderManager.default.signalEnumerator(for: NSFileProviderItemIdentifier(rawValue: parentId)) { _ in }
                } else {
                    // Fallback on earlier versions
                }
            case .failure:
                break
            }
        }

        if file.isDirectory {
            return self.createDirectory(name: file.name, ownerId: file.ownerId, parentId: file.parentDirectory?.id, completionHandler: requestCompletion)
        } else {
            return self.createFileMetadata(name: file.name, mimeType: file.mimeType!, size: Int(file.size), flatName: file.name, owner: file.owner, parentId: file.parentDirectory?.id, completionHandler: requestCompletion)
        }
    }
}

extension FileSync: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let id = downloadTask.taskDescription else {
            fatalError("No ID given to task")
        }

        guard let transferInfo = runningTask[id] else {
            fatalError("Impossible to download file without providing transferInfo")
        }

        do {
            try FileManager.default.moveItem(at: location, to: transferInfo.localFileURL)
        } catch let error {
            transferInfo.completionHandler.error(SCError.other(error.localizedDescription))
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let id = task.taskDescription else {
            fatalError("No ID given to task")
        }

        guard let transferInfo = runningTask[id] else {
            fatalError("Impossible to download file without providing transferInfo")
        }

        if let error = error {
            transferInfo.completionHandler.error(SCError.network(error))
        } else {
            switch transferInfo.completionHandler {
            case .downloadHandler(let handler):
                handler(.success( transferInfo.localFileURL))
            case .uploadHandler(let handler):
                handler(.success(()))
            }
        }

        runningTask.removeValue(forKey: id)
    }
}
