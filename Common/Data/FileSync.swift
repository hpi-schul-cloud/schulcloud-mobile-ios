//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import Foundation
import Marshal
import Result

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

    private func getQueryURL(for file: File, baseURL: URL) -> URL? {
        guard let remoteURL = file.remoteURL else { return nil }

        var urlComponent = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponent.query = "path=\(remoteURL.path.removingPercentEncoding!)/"
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
    public func signedURL(resourceAt url: URL, mimeType: String, forUpload: Bool, completionHandler: @escaping (Result<SignedURLInfo, SCError>) -> Void) -> URLSessionTask? {

        var request = self.POSTRequest(for: fileStorageURL.appendingPathComponent("signedUrl") )

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

    public func createFileMetadata(at remoteURL: URL,
                                   mimeType: String,
                                   size: Int,
                                   flatName: String,
                                   thumbnailURL: URL,
                                   completionHandler: @escaping (Result<[String: Any], SCError>) -> Void) -> URLSessionTask? {

        var request = self.POSTRequest(for: Brand.default.servers.backend.appendingPathComponent("files"))
        let parameters: [String: Any] = [
            "key":  remoteURL.absoluteString.removingPercentEncoding!,
            "path": remoteURL.deletingLastPathComponent().absoluteString.removingPercentEncoding!,
            "name": remoteURL.lastPathComponent.removingPercentEncoding!,
            "type": mimeType,
            "size": size,
            "flatFileName": flatName,
            "thumbnail": thumbnailURL.absoluteString,
            "studentCanEdit": false,
            "schoolId": Globals.currentUser!.schoolId,
            ]

        guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            completionHandler(.failure(SCError.jsonSerialization("Can't serialize file metadata")))
            return nil
        }

        request.httpBody = data
        return self.metadataSession.dataTask(with: request) { (data, response, error) in
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

    public func create(directoryAt url: URL,
                       completionHandler: @escaping (Result<[String: Any], SCError>) -> Void) -> URLSessionTask? {

        var request = self.POSTRequest(for: fileStorageURL.appendingPathComponent("directories") )

        guard var pathString = url.absoluteString.removingPercentEncoding else {
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
            case .failure(_):
                break
            }
        }

        if file.isDirectory {
            return self.create(directoryAt: file.remoteURL!, completionHandler: requestCompletion)
        } else {
            return self.createFileMetadata(
                at: file.remoteURL!,
                mimeType: file.mimeType!,
                size: Int(file.size),
                flatName: file.name,
                thumbnailURL: file.remoteURL!,
                completionHandler: requestCompletion)
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
