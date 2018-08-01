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

    static public var `default`: FileSync = FileSync()

    public typealias ProgressHandler = (Float) -> Void

    private var backgroundSession: URLSession!
    private var foregroundSession: URLSession!
    private let metadataSession: URLSession

    private struct FileTransferInfo {
        let promise: Promise<URL, SCError>
        let progressHandler: ProgressHandler
        let localFileURL: URL
        let fileID: NSManagedObjectID
    }

    private var runningTask: [Int: FileTransferInfo] = [:]

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
            return Future(value: ())
        }

        switch directory.id {
        case FileHelper.coursesDirectoryID:
            return CourseHelper.syncCourses().asVoid()
        case FileHelper.sharedDirectoryID:
            return self.downloadSharedFiles().flatMap { objects -> Future<Void, SCError> in
                return objects.map { json in
                    return FileHelper.updateDatabase(contentsOf: directory, using: json)
                }.sequence().asVoid()
            }
        default:
            return self.downloadContent(of: directory).flatMap { json -> Future<Void, SCError> in
                return FileHelper.updateDatabase(contentsOf: directory, using: json)
            }.asVoid()
        }
    }

    private func downloadContent(of directory: File) -> Future<[String: Any], SCError> {
        guard directory.isDirectory else {
            return Future(error: .other("only works on directory"))
        }

        guard let queryURL = self.getQueryURL(for: directory) else {
            return Future(error: .other("no remote URL"))
        }

        let request = self.request(for: queryURL)
        let promise: Promise<[String: Any], SCError> = Promise()
        self.metadataSession.dataTask(with: request) { data, response, error in
            let result = Result<Data, SCError> {
                return try self.confirmNetworkResponse(data: data, response: response, error: error)
            }.flatMap { responseData -> Result<[String: Any], SCError> in
                guard let json = (try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments)) as? [String: Any] else {
                    return .failure(SCError.jsonDeserialization("Can't deserialize"))
                }

                return .success(json)
            }

            promise.complete(result)
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
                         progressHandler: @escaping ProgressHandler ) -> Future<URL, SCError> {
        assert(file.downloadState != .downloading)
        let localURL = file.localURL
        let downloadSession: URLSession = background ? self.backgroundSession : self.foregroundSession
        guard [File.DownloadState.notDownloaded, File.DownloadState.downloadFailed].contains(file.downloadState) else {
            progressHandler(1.0)
            return Future<URL, SCError>(value: localURL)
        }

        let fileID = file.objectID
        let backgroundContext = CoreDataHelper.persistentContainer.newBackgroundContext()
        backgroundContext.performAndWait {
            let file = backgroundContext.object(with: fileID) as! File
            file.downloadState = .downloading
        }

        _ = backgroundContext.saveWithResult()

        return signedURL(for: file).flatMap { url -> Future<URL, SCError> in
            return self.download(signedURL: url, fileID: fileID, moveTo: localURL, downloadSession: downloadSession, progressHandler: progressHandler)
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
                              fileID: NSManagedObjectID,
                              moveTo localURL: URL,
                              downloadSession: URLSession,
                              progressHandler: @escaping ProgressHandler) -> Future<URL, SCError> {
        let promise = Promise<URL, SCError>()
        let transferInfo = FileTransferInfo(promise: promise, progressHandler: progressHandler, localFileURL: localURL, fileID: fileID)
        let task = downloadSession.downloadTask(with: signedURL)
        task.resume()
        runningTask[task.taskIdentifier] = transferInfo
        return promise.future
    }

}

extension FileSync: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let transferInfo = runningTask[downloadTask.taskIdentifier] else {
            fatalError("Impossible to download file without providing transferInfo")
        }

        do {
            try FileManager.default.moveItem(at: location, to: transferInfo.localFileURL)
        } catch _ {
            transferInfo.promise.failure(.other("Tried to download file that already is downloaded"))
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let transferInfo = runningTask[task.taskIdentifier] else {
            fatalError("Impossible to download file without providing transferInfo")
        }

        if let error = error {
            transferInfo.promise.failure(.network(error))
        } else {
            transferInfo.promise.success(transferInfo.localFileURL)
        }

        let fileID = transferInfo.fileID
        CoreDataHelper.persistentContainer.performBackgroundTask { context in
            let file = context.object(with: fileID) as! File
            file.downloadState = .downloaded
            _ = context.saveWithResult()
        }

        runningTask.removeValue(forKey: task.taskIdentifier)
    }

    // Download progress
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        if let progressHandler = runningTask[downloadTask.taskIdentifier]?.progressHandler {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            progressHandler(progress)
        }
    }
}
