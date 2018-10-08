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

    private var backgroundSession: URLSession!
    private var foregroundSession: URLSession!
    private let metadataSession: URLSession

    private struct FileTransferInfo {
        let task: URLSessionTask
        let completionHandler: FileDownloadHandler
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

    public func updateContent(of directory: File, completionBlock: @escaping (Result<[File], SCError>) -> Void) -> URLSessionTask? {
        guard FileHelper.rootDirectoryID != directory.id else {
            completionBlock(Result(value: Array(directory.contents)))
            return nil
        }

        let taskCompletionBlock: (Result<[String:Any], SCError>) -> Void = { result in
            switch result {
            case .success(let json):
                let result = FileHelper.updateDatabase(contentsOf: directory, using: json)
                completionBlock(result)
            case .failure(let error):
                completionBlock(Result(error: error))
            }
        }

        switch directory.id {
        case FileHelper.coursesDirectoryID:
            CourseHelper.syncCourses().flatMap { _ -> Future<[File], SCError> in
                let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
                fetchRequest.predicate = NSPredicate(format: "parentDirectory.id == %@", FileHelper.coursesDirectoryID)

                let result = CoreDataHelper.viewContext.fetchMultiple(fetchRequest)
                guard let files = result.value else {
                    return Future(error: result.error!)
                }

                return Future(value: files)
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
            completionBlock(Result(error: SCError.other("only works on directory")))
            return nil
        }

        guard let queryURL = self.getQueryURL(for: directory) else {
            completionBlock(Result(error: SCError.other("no remote URL")))
            return nil
        }

        let request = self.request(for: queryURL)
        return self.metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                completionBlock(Result(value: json))
            } catch let error as SCError {
                completionBlock(Result(error: error))
            } catch let error {
                completionBlock(Result(error: SCError.other(error.localizedDescription)))
            }
        }
    }

    public func downloadSharedFiles(completionBlock: @escaping (Result<[String: Any], SCError>) -> Void) -> URLSessionTask {

        let request = self.request(for: Brand.default.servers.backend.appendingPathComponent("files") )
        return metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! MarshaledObject
                let files: [MarshaledObject] = try json.value(for: "data")
                let sharedFiles = files.filter { object -> Bool in
                    return (try? object.value(for: "context")) == "geteilte Datei"
                }

                let result: [String: Any] = [
                    "files": sharedFiles,
                    "directories": [],
                ]

                completionBlock(Result(value: result))
            } catch let error as SCError {
                completionBlock(Result(error: error))
            } catch let error {
                completionBlock(Result(error: SCError.jsonDeserialization(error.localizedDescription) ))
            }
        }
    }

    // MARK: File materialization
    public func signedURL(for file: File, completionHandler: @escaping (Result<URL, SCError>) -> Void) -> URLSessionTask? {
        guard !file.isDirectory else {
            completionHandler(Result(error: SCError.other("Can't download folder") ))
            return nil
        }

        var request = self.request(for: fileStorageURL.appendingPathComponent("signedUrl") )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: Any = [
            "path": file.remoteURL!.absoluteString.removingPercentEncoding!,
            //            "fileType": mime.lookup(file),
            "action": "getObject",
        ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

        return metadataSession.dataTask(with: request) { data, response, error in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let signedURL: URL = try (json as! MarshaledObject).value(for: "url")
                completionHandler(Result(value: signedURL))
            } catch let error as SCError {
                completionHandler(Result(error: error))
            } catch let error {
                completionHandler(Result(error: SCError.jsonDeserialization(error.localizedDescription)))
            }
        }
    }

    public func downloadThumbnail(from file: File,
                                  background: Bool = false,
                                  completionHandler: @escaping FileDownloadHandler) -> URLSessionTask? {
        guard !FileManager.default.fileExists(atPath: file.localThumbnailURL.path) else {
            completionHandler(Result(value: file.localThumbnailURL))
            return nil
        }

        guard let url = file.thumbnailRemoteURL else {
            completionHandler(Result(error: SCError.other("No thumbnail to download")))
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

        let transferInfo = FileTransferInfo(task: task, completionHandler: completionHandler, localFileURL: localURL)
        runningTask[id] = transferInfo

        return task
    }
}

extension FileSync: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
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
            transferInfo.completionHandler(Result(error :SCError.other(error.localizedDescription)))
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
            transferInfo.completionHandler(Result(error: SCError.network(error)))
        } else {
            transferInfo.completionHandler(Result(value: transferInfo.localFileURL))
        }

        runningTask.removeValue(forKey: id)
    }
}
