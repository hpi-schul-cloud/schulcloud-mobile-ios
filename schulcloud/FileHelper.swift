//
//  FileHelper.swift
//  schulcloud
//
//  Created by Carl Gödecken on 18.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Alamofire
import BrightFutures
import CoreData
import Marshal

class FileSync : NSObject {

    typealias ProgressHandler = (Float) -> ()
    
    fileprivate var fileTransferSession : URLSession! = nil
    fileprivate let fileDataSession : URLSession

    var runningTask : [Int: Promise<Data, SCError>] = [:]
    var progressHandlers : [Int : ProgressHandler] = [:]

    override init() {

        let configuration = URLSessionConfiguration.ephemeral
        fileDataSession = URLSession(configuration: URLSessionConfiguration.default)
        
        super.init()
        
        fileTransferSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    deinit {
        fileDataSession.invalidateAndCancel()
        fileTransferSession.invalidateAndCancel()
    }

    private var fileStorageURL : URL {
        return Constants.backend.url.appendingPathComponent("fileStorage")
    }
    
    private func getUrl(for file: File) -> URL? {
        var urlComponent = URLComponents(url: fileStorageURL, resolvingAgainstBaseURL: false)!
        urlComponent.query = "path=\(file.url.absoluteString)"
        return try? urlComponent.asURL()
    }
    
    private func request(for url: URL) -> URLRequest {
        
        var request = URLRequest(url: url)
        request.setValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        return request
    }
    
    func downloadContent(for file: File) -> Future<([String : Any]), SCError> {
        guard file.isDirectory else { return Future(error: .other("only works on directory") ) }
        
        let request = self.request(for: getUrl(for: file)! )
        let promise : Promise<[String : Any], SCError> = Promise()
        fileDataSession.dataTask(with: request) { (data, response, error) in
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

            guard let json = (try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments)) as? [String : Any] else {
                promise.failure(SCError.jsonDeserialization("Can't deserialize"))
                return
            }

            promise.success(json)
        }.resume()
        return promise.future
    }
    
    func download(url: URL, progressHandler: @escaping ProgressHandler ) -> Future<Data, SCError> {
        let promise = Promise<Data, SCError>()
        let task = fileTransferSession.downloadTask(with: url)
        task.resume()
        runningTask[task.taskIdentifier] = promise
        progressHandlers[task.taskIdentifier] = progressHandler
        return promise.future
    }
    
    func signedURL(for file: File) -> Future<URL, SCError> {
        guard !file.isDirectory else { return Future(error: .other("Can't download folder") ) }
        
        var request = self.request(for: fileStorageURL.appendingPathComponent("signedUrl") )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: Any = [
            "path": file.url.absoluteString.removingPercentEncoding!,
            //"fileType": mime.lookup(file),
            "action": "getObject"
        ]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        
        let promise = Promise<URL, SCError>()
        fileDataSession.dataTask(with: request) { (data, response, error) in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let signedURL = try SignedUrl(object: json as! MarshaledObject)
                promise.success(signedURL.url)
            } catch let error as SCError {
                promise.failure(error)
            } catch let error {
                promise.failure(.jsonDeserialization(error.localizedDescription) )
            }
        }.resume()
        return promise.future
    }

    func sharedDownload() -> Future<[[String:Any]], SCError> {
        let promise = Promise<[[String:Any]], SCError>()
        
        let request = self.request(for: Constants.backend.url.appendingPathComponent("files") )
        fileDataSession.dataTask(with: request) { (data, response, error) in
            do {
                let data = try self.confirmNetworkResponse(data: data, response: response, error: error)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! MarshaledObject
                let files : [MarshaledObject] = try json.value(for: "data")
                let sharedFiles = files.filter({ (object) -> Bool in
                    return (try? object.value(for: "context")) == "geteilte Datei"
                })
                promise.success(sharedFiles as! [[String:Any]])
            } catch let error as SCError {
                promise.failure(error)
            } catch let error {
                promise.failure(.jsonDeserialization(error.localizedDescription) )
            }
        }.resume()
        return promise.future
    }
    
    private func confirmNetworkResponse(data: Data?, response: URLResponse?, error: Error?) throws -> Data{
        guard error == nil else {
            throw SCError.network(error)
        }
        guard let response = response as?  HTTPURLResponse,
            200 ... 299 ~= response.statusCode else {
                throw SCError.network(nil)
        }
        guard let data = data else {
            throw SCError.network(nil)
        }
        return data
    }
    
}

extension FileSync : URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let promise = runningTask[downloadTask.taskIdentifier]
        do {
            let data = try Data(contentsOf: location)
            promise?.success(data)
        } catch let error {
            promise?.failure(.other(error.localizedDescription))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let promise = runningTask[task.taskIdentifier]
        if let error = error {
            promise?.failure(.network(error))
        }
        runningTask.removeValue(forKey: task.taskIdentifier)
        progressHandlers.removeValue(forKey: task.taskIdentifier)
    }
    
    // Download progress
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let progressHandler = progressHandlers[downloadTask.taskIdentifier] {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            progressHandler(progress)
        }
    }
}

class FileHelper {
    static var rootDirectoryID = "root"
    static var coursesDirectoryID = "courses"
    static var sharedDirectoryID = "shared"

    private static var notSynchronizedPath : [String] = {
        return [rootDirectoryID]
    }()
    
    fileprivate static var userDataRootURL: URL {
        let userId = Globals.account?.userId ?? "0"
        let url = URL(string: "users")!
        return url.appendingPathComponent(userId, isDirectory: true)
    }
    
    fileprivate static var coursesDataRootURL : URL = {
        return URL(string: coursesDirectoryID)!
    }()
    
    fileprivate static var sharedDataRootURL : URL = {
        return URL(string: sharedDirectoryID)!
    }()
    
    static var rootFolder: File {
        return fetchRootFolder() ?? createBaseStructure()
    }
    
    fileprivate static func fetchRootFolder() -> File? {
        let fetchRequest = NSFetchRequest(entityName: "File") as NSFetchRequest<File>
        fetchRequest.predicate = NSPredicate(format: "currentPath == %@", rootDirectoryID)
        
        do {
            let result = try managedObjectContext.fetch(fetchRequest)
            return result.first
        } catch _ {
            return nil
        }
    }
    
    /// Create the basic folder structure and return main Root
    fileprivate static func createBaseStructure() -> File {
        do {
            let rootFolder = File(context: managedObjectContext)
            rootFolder.id = rootDirectoryID
            rootFolder.name = "Daitein"
            rootFolder.isDirectory = true
            rootFolder.currentPath = rootDirectoryID
            rootFolder.permissions = .read
            
            let userRootFolder = File(context: managedObjectContext)
            userRootFolder.id = userDataRootURL.absoluteString
            userRootFolder.name = "My Data"
            userRootFolder.isDirectory = true
            userRootFolder.currentPath = userDataRootURL.absoluteString
            userRootFolder.parentDirectory = rootFolder
            userRootFolder.permissions = .read
            
            let coursesRootFolder = File(context: managedObjectContext)
            coursesRootFolder.id = coursesDirectoryID
            coursesRootFolder.name = "Courses Data"
            coursesRootFolder.isDirectory = true
            coursesRootFolder.currentPath = coursesDataRootURL.absoluteString
            coursesRootFolder.parentDirectory = rootFolder
            coursesRootFolder.permissions = .read

            let sharedRootFolder = File(context: managedObjectContext)
            sharedRootFolder.id = sharedDirectoryID
            sharedRootFolder.name = "Shared Data"
            sharedRootFolder.isDirectory = true
            sharedRootFolder.currentPath = sharedDataRootURL.absoluteString
            sharedRootFolder.parentDirectory = rootFolder
            sharedRootFolder.permissions = .read

            try managedObjectContext.save()
            
            return rootFolder
        } catch let error {
            fatalError("Unresolved error \(error)") // TODO: replace this with something more friendly
        }
    }
    
    static func getFolder(withPath path: String) -> File? {
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "currentPath == %@", path)
        do {
            let result = try managedObjectContext.fetch(fetchRequest)
            if let file = result.first {
                return file
            }
        } catch let error {
            log.error("Unresolved error \(error)")
        }
        return nil
    }
    
    static func delete(file: File) -> Future< Void, SCError> {
        struct DidSuccess : Unmarshaling {
            init(object: MarshaledObject) throws {
            }
        }
        
        var path = URL(string: "fileStorage")
        if file.isDirectory { path?.appendPathComponent("directories", isDirectory: true) }
        path?.appendPathComponent(file.id)
        
        let parameters: Parameters = ["path": file.currentPath]
        
        //TODO: Figure out the success structure
        let request : Future<DidSuccess, SCError> = ApiHelper.request(path!.absoluteString, method: .delete, parameters: parameters, encoding: JSONEncoding.default).deserialize(keyPath: "")
        return request.map { _ in
            return Void()
        }
    }
    
    static func getSignedUrl(forFile file: File) -> Future<URL, SCError> {
        let parameters: Parameters = [
            "path": file.url.absoluteString.removingPercentEncoding!,
            //"fileType": mime.lookup(file),
            "action": "getObject"
        ]
        let request: Future<SignedUrl, SCError> = ApiHelper.request("fileStorage/signedUrl", method: .post, parameters: parameters, encoding: JSONEncoding.default).deserialize(keyPath: "")
        
        return request.flatMap { signedUrl -> Future<URL, SCError> in
            return Future(value: signedUrl.url)
        }
    }
    
    static func process(changes: [String: [Course] ], inFolder parentFolder: File, managedObjectContext: NSManagedObjectContext) {
        if let deletedCourses = changes[NSDeletedObjectsKey],
               deletedCourses.count > 0 {
            let contents = parentFolder.mutableSetValue(forKey: "contents")
            for course in deletedCourses {
                contents.remove(course)
            }
        }
        if let updated = changes[NSUpdatedObjectsKey],
            updated.count > 0,
            let contents = parentFolder.contents as? Set<File> {
            for course in updated {
                guard let file = contents.first(where: { $0.id == course.id }) else { continue; }
                
                file.currentPath = parentFolder.url.appendingPathComponent(course.id, isDirectory: true).absoluteString
                file.name = course.name
                file.isDirectory = true
                file.parentDirectory = parentFolder
            }
        }
        if let inserted = changes[NSInsertedObjectsKey],
            inserted.count > 0 {
            for course in inserted {
                let file = File(context: managedObjectContext)
                
                file.id = course.id
                file.currentPath = parentFolder.url.appendingPathComponent(course.id, isDirectory: true).absoluteString
                file.name = course.name
                file.isDirectory = true
                file.parentDirectory = parentFolder
            }
        }
    }
    
    static func updateDatabase(contentsOf parentFolder: File, using contents: [String: Any]) {
        do {
            let files: [[String: Any]] = try contents.value(for: "files")
            let folders: [[String: Any]] = try contents.value(for: "directories")
            
            let createdFiles = try files.map({ try File.createOrUpdate(inContext: managedObjectContext, parentFolder: parentFolder, isDirectory: false, data: $0) })
            let createdFolders = try folders.map({ try File.createOrUpdate(inContext: managedObjectContext, parentFolder: parentFolder, isDirectory: true, data: $0) })
            
            // remove deleted files or folders
            let foundPaths = createdFiles.map({$0.currentPath}) + createdFolders.map({$0.currentPath})
            let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
            let notOnServerPredicate = NSPredicate(format: "NOT (currentPath IN %@)", foundPaths)
            let fetchRequest = NSFetchRequest<File>(entityName: "File")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notOnServerPredicate, parentFolderPredicate])
            
            try CoreDataHelper.delete(fetchRequest: fetchRequest)
        } catch let error {
            log.error(error)
        }
        
        saveContext()
    }
}

struct SignedUrl: Unmarshaling {
    let url: URL
    
    init(object: MarshaledObject) throws {
        url = try object.value(for: "url")
    }
}
