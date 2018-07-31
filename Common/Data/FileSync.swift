//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Foundation
import Marshal
import Result

public class FileSync: NSObject {

    static public var `default`: FileSync = FileSync()

    public typealias ProgressHandler = (Float) -> Void

    private var backgroundSession: URLSession!
    private var foregroundSession: URLSession!
    private let metadataSession: URLSession

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
