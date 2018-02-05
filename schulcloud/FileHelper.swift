//
//  FileHelper.swift
//  schulcloud
//
//  Created by Carl Gödecken on 18.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//


//TODO: fetch course if no local course
//TODO: fetch shared files from other endpoint


import Foundation
import Alamofire
import BrightFutures
import CoreData
import Marshal

class FileHelper {
    
    private static var rootDirectoryName = "root"
    private static var coursesDirectoryName = "courses"
    private static var sharedDirectoryName = "shared"
    
    private static var notSynchronizedPath : [String] = {
        return [rootDirectoryName]
    }()
    
    fileprivate static var userDataRootURL: URL {
        let userId = Globals.account?.userId ?? "0"
        return URL(string: "users/\(userId)")!
    }
    
    fileprivate static var coursesDataRootURL : URL = {
        return URL(string: coursesDirectoryName)!
    }()
    
    fileprivate static var sharedDataRooURL : URL = {
        return URL(string: sharedDirectoryName)!
    }()
    
    static var rootFolder: File {
        return fetchRootFolder() ?? createBaseStructure()
    }
    
    fileprivate static func fetchRootFolder() -> File? {
        let fetchRequest = NSFetchRequest(entityName: "File") as NSFetchRequest<File>
        fetchRequest.predicate = NSPredicate(format: "currentPath == %@", rootDirectoryName)
        
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
            rootFolder.id = "root"
            rootFolder.name = "Daitein"
            rootFolder.isDirectory = true
            rootFolder.currentPath = "root"
            
            let userRootFolder = File(context: managedObjectContext)
            userRootFolder.id = "\(userDataRootURL.absoluteString)"
            userRootFolder.name = "My Data"
            userRootFolder.isDirectory = true
            userRootFolder.currentPath = userDataRootURL.absoluteString
            userRootFolder.parentDirectory = rootFolder
            
            let coursesRootFolder = File(context: managedObjectContext)
            coursesRootFolder.id = "\(coursesDataRootURL.absoluteString)"
            coursesRootFolder.name = "Courses Data"
            coursesRootFolder.isDirectory = true
            coursesRootFolder.currentPath = coursesDataRootURL.absoluteString
            coursesRootFolder.parentDirectory = rootFolder

            let sharedRootFolder = File(context: managedObjectContext)
            sharedRootFolder.id = "shared"
            sharedRootFolder.name = "Shared Data"
            sharedRootFolder.isDirectory = true
            sharedRootFolder.currentPath = sharedDataRooURL.absoluteString
            sharedRootFolder.parentDirectory = rootFolder

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
    
    static func updateDatabase(forFolder parentFolder: File) -> Future<Void, SCError> {
        guard !notSynchronizedPath.contains(parentFolder.url.absoluteString) else {
            return Future(value: Void() )
        }
        
        let promise: Promise<Void, SCError> = Promise()
        if coursesDirectoryName == parentFolder.url.absoluteString {
            CourseHelper.fetchFromServer()
            .onSuccess { changes in
                process(changes: changes, inFolder: parentFolder, managedObjectContext: managedObjectContext)
                try! managedObjectContext.save()
                promise.success( () )
            }
            .onFailure { error in
                promise.failure(error)
            }
            return promise.future
            
        } else if sharedDirectoryName == parentFolder.url.absoluteString {
            return ApiHelper.request("files").jsonArrayFuture(keyPath: "data")
            .flatMap { json -> Future<Void, SCError> in
                let sharedFiles = json.filter { (try? $0.value(for: "context")) == "geteilte Datei" }
                for json in sharedFiles {
                    updateDatabase(contentsOf: parentFolder, using: json)
                }
                return Future( value: Void() )
            }
        } else {
            let path = "fileStorage?path=\(parentFolder.url.absoluteString)/"
            return ApiHelper.request(path).jsonObjectFuture()
                .flatMap { json -> Future<Void, SCError> in
                    updateDatabase(contentsOf: parentFolder, using: json)
                    return Future(value: Void())
            }
        }
    }
    
    fileprivate static func process(changes: [String: [Course] ], inFolder parentFolder: File, managedObjectContext: NSManagedObjectContext) {
        if let deleteCourses = changes[NSDeletedObjectsKey] {
            let contents = parentFolder.mutableSetValue(forKey: "contents")
            for course in deleteCourses {
                contents.remove(course)
            }
        }
        if let updated = changes[NSUpdatedObjectsKey],
            let contents = parentFolder.contents as? Set<File>
        {
            for course in updated {
                guard let file = contents.first(where: { $0.id == course.id }) else { continue; }
                
                file.currentPath = parentFolder.url.appendingPathComponent(course.id).absoluteString
                file.name = course.name
                file.isDirectory = true
                file.parentDirectory = parentFolder
            }
        }
        if let inserted = changes[NSInsertedObjectsKey]
        {
            for course in inserted {
                let file = File(context: managedObjectContext)
                
                file.id = course.id
                file.currentPath = parentFolder.url.appendingPathComponent(course.id).absoluteString
                file.name = course.name
                file.isDirectory = true
                file.parentDirectory = parentFolder
            }
        }
    }
    
    fileprivate static func updateDatabase(contentsOf parentFolder: File, using contents: [String: Any]) {
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
    
    struct SignedUrl: Unmarshaling {
        let url: URL
        
        init(object: MarshaledObject) throws {
            url = try object.value(for: "url")
        }
    }
}
