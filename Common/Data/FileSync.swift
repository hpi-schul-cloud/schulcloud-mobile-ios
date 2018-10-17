//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import Foundation
import Marshal
import Result

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

    private func getQueryURL(for file: File, baseURL: URL) -> URL? {
        guard let remoteURL = file.remoteURL else { return nil }

        var urlComponent = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponent.query = "path=\(remoteURL.path.removingPercentEncoding!)/"
        return try? urlComponent.asURL()
    }


    private func GETRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        return request
    }

    private func POSTRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        return request
    }

    private func DELETERequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        return request
    }

    private func PUTRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        return request
    }

    private func confirmNetworkResponse(data datao: Data?, response responseo: URLResponse?, error erroro: Error?) throws -> Data {
        guard erroro == nil else {
            throw SCError.network(erroro!)
        }

        guard let response = responseo as? HTTPURLResponse,
            200 ... 299 ~= response.statusCode else {
                throw SCError.network(nil)
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

        let taskCompletionBlock: (Result<[String: Any], SCError>) -> Void = { result in
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

    private func downloadContent(of directory: File, completionBlock: @escaping (Result<[String: Any], SCError>) -> Void) -> URLSessionTask? {
        guard directory.isDirectory else {
            completionBlock(.failure( SCError.other("only works on directory")))
            return nil
        }

        guard let queryURL = self.getQueryURL(for: directory, baseURL: self.fileStorageURL) else {
            completionBlock(.failure( SCError.other("no remote URL")))
            return nil
        }

        let request = self.GETRequest(for: queryURL)
        return self.metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
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

    public func downloadSharedFiles(completionBlock: @escaping (Result<[String: Any], SCError>) -> Void) -> URLSessionTask {

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
                }

                let result: [String: Any] = [
                    "files": sharedFiles,
                    "directories": [],
                ]

                completionBlock(.success(result))
            } catch let error as SCError {
                completionBlock(.failure(error))
            } catch let error {
                completionBlock(.failure(SCError.jsonDeserialization(error.localizedDescription)))
            }
        }
    }

    // MARK: File materialization
    public func signedURL(resourceAt url: URL, mimeType: String, forUpload: Bool, completionHandler: @escaping (Result<URL, SCError>) -> Void) -> URLSessionTask? {

        var request = self.POSTRequest(for: fileStorageURL.appendingPathComponent("signedUrl") )
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var parameters: [String: Any] = [
            "path": url.absoluteString.removingPercentEncoding!,
            "action": forUpload ? "putObject" : "getObject",
        ]

        if forUpload {
            parameters["fileType"] = mimeType
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
                completionHandler(.success( signedURL))
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

    public func createFileMetadata(at url: URL,
                           name: String,
                           mimeType: String,
                           parentDirectory: File,
                           completionHandler: @escaping (Result<File, SCError>) -> Void) -> URLSessionTask? {

        var request = self.POSTRequest(for: self.fileStorageURL.appendingPathComponent("files").appendingPathComponent("new"))
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "key": url.appendingPathComponent(name).absoluteString.removingPercentEncoding!,
            "path": url.absoluteString.removingPercentEncoding!,
            "name": name,
            "studentCanEdit": true,
            "schoolId": "5bbb48be663ff7001158fef1",
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            completionHandler(.failure(SCError.jsonSerialization("Can't serialize file metadata")))
            return nil
        }

        request.httpBody = data

        let parentID = parentDirectory.objectID
        return self.metadataSession.dataTask(with: request) { (data, response, error) in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? MarshaledObject else {
                    throw SCError.jsonDeserialization("Object can't be marshaled")
                }
                
                let context = CoreDataHelper.persistentContainer.newBackgroundContext()
                let file = try context.performAndWait { () -> File in
                    let parent = context.typedObject(with: parentID) as File
                    return try File.createOrUpdate(inContext: context, parentFolder: parent, isDirectory: false, data: json)
                }
                completionHandler(.success(file))
            } catch let error as SCError {
                completionHandler(.failure(error))
            } catch let error {
                completionHandler(.failure(SCError.other(error.localizedDescription)))
            }
        }
    }

    public func createDirectory(path: URL,
                                parentDirectory: File,
                                completionHandler: @escaping (Result<File, SCError>) -> Void) -> URLSessionTask? {

        var request = self.POSTRequest(for: fileStorageURL.appendingPathComponent("directories") )
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard var pathString = path.absoluteString.removingPercentEncoding else {
            return nil
        }
        pathString.removeLast()

        let parameters: [String: Any] = [
            "path": pathString,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            completionHandler( .failure(.jsonSerialization("Failed serielizing json")))
            return nil
        }

        request.httpBody = jsonData

        let fileID = parentDirectory.objectID

        return self.metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? MarshaledObject else {
                    throw SCError.jsonDeserialization("Unexpected JSON Type")
                }

                let context = CoreDataHelper.persistentContainer.newBackgroundContext()
                let result = context.performAndWait { () -> Result<File, SCError> in
                    let parentFolder = context.typedObject(with: fileID) as File
                    do {
                        let createdFile = try File.createOrUpdate(inContext: context,
                                                                  parentFolder: parentFolder,
                                                                  isDirectory: true,
                                                                  data: json)
                        return .success(createdFile)
                    } catch let error {
                        return .failure(SCError.other(error.localizedDescription))
                    }
                }

                completionHandler(result)
            } catch let error as SCError {
                completionHandler(.failure(error))
            } catch let error {
                completionHandler(.failure(SCError.other(error.localizedDescription)))
            }
        }
    }

    public func rename(directory: File,
                       newName: String,
                       completionHandler: @escaping (Result<Void, SCError>) -> Void) -> URLSessionTask? {
        assert(directory.isDirectory)

        var request = self.POSTRequest(for: fileStorageURL.appendingPathComponent("directories/rename") )
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let remoteURL = directory.remoteURL,
            var pathString = remoteURL.absoluteString.removingPercentEncoding else {
            return nil
        }
        pathString.removeLast() // a '/' is always appended for directory, but the endpoint won't find directory if it is kept, so removing it

        let parameters: [String: Any] = [
            "path": pathString,
            "newName": newName
            ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            completionHandler( .failure(.jsonSerialization("Failed serielizing json")))
            return nil
        }

        request.httpBody = jsonData
        let folderID = directory.objectID

        return self.metadataSession.dataTask(with: request) { data, response, error in
            do {
                _ = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let context = CoreDataHelper.persistentContainer.newBackgroundContext()
                context.performAndWait {
                    let folder = context.typedObject(with: folderID) as File
                    folder.name = newName
                    _ = context.saveWithResult()
                }

                completionHandler(.success(()))
            } catch let error as SCError {
                completionHandler(.failure(error))
            } catch let error {
                completionHandler(.failure(SCError.other(error.localizedDescription)))
            }
        }
    }

    public func delete(directory: File,
                       completionHandler: @escaping (Result<Void, SCError>) -> Void) -> URLSessionTask? {
        assert(directory.isDirectory)

        let folderID = directory.objectID

        guard let remoteURL = directory.remoteURL else { return nil }

        var urlComponent = URLComponents(url: self.fileStorageURL.appendingPathComponent("directories", isDirectory: true), resolvingAgainstBaseURL: false)!
        urlComponent.query = "path=\(remoteURL.path.removingPercentEncoding!)"

        guard let queryURL = try? urlComponent.asURL() else {
            completionHandler(.failure(SCError.other("Can't build query URL")))
            return nil
        }

        let request = self.DELETERequest(for: queryURL)
        return self.metadataSession.dataTask(with: request) { data, response, error in
            do {
                _ = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let context = CoreDataHelper.persistentContainer.newBackgroundContext()
                context.performAndWait {
                    let deletedItem = context.typedObject(with: folderID)
                    context.delete(deletedItem)
                    _ = context.saveWithResult()
                }

                completionHandler(.success(()))
            } catch let error as SCError {
                completionHandler(.failure(error))
            } catch let error {
                completionHandler(.failure(SCError.other(error.localizedDescription)))
            }
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
