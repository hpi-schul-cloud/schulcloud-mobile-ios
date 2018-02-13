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

class FileHelper {
    static var rootUrl: URL {
        let userId = Globals.account?.userId ?? "0"
        return URL(string: "users/\(userId)/")!
    }
    
    static var rootFolder: File {
        return createRootFolder()
    }
    
    static func createRootFolder() -> File {
        let fetchRequest = NSFetchRequest(entityName: "File") as NSFetchRequest<File>
        fetchRequest.predicate = NSPredicate(format: "pathString == %@", rootUrl.absoluteString)
        
        do {
            let result = try CoreDataHelper.managedObjectContext.fetch(fetchRequest)
            if let file = result.first {
                file.pathString = rootUrl.absoluteString
                CoreDataHelper.saveContext()
                return file
            }
            let file = File(context: CoreDataHelper.managedObjectContext)
            
            file.displayName = "Meine Dateien"
            file.isDirectory = true
            file.pathString = rootUrl.absoluteString
            file.typeString = "directory"
            CoreDataHelper.saveContext()
            return file
        } catch let error {
            fatalError("Unresolved error \(error)") // TODO: replace this with something more friendly
        }
    }
    
    static func getFolder(withPath path: String) -> File? {
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pathString == %@", path)
        do {
            let result = try CoreDataHelper.managedObjectContext.fetch(fetchRequest)
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
            "path": file.path.absoluteString.removingPercentEncoding!,
            //"fileType": mime.lookup(file),
            "action": "getObject"
        ]
        let request: Future<SignedUrl, SCError> = ApiHelper.request("fileStorage/signedUrl", method: .post, parameters: parameters, encoding: JSONEncoding.default).deserialize(keyPath: "")
        
        return request.flatMap { signedUrl -> Future<URL, SCError> in
            return Future(value: signedUrl.url)
        }
    }
    
    static func updateDatabase(forFolder parentFolder: File) -> Future<Void, SCError> {
        let path = "fileStorage?path=\(parentFolder.path.absoluteString)"
        
        return ApiHelper.request(path).jsonObjectFuture()
            .flatMap { json -> Future<Void, SCError> in
                    updateDatabase(contentsOf: parentFolder, using: json)
                    return Future(value: Void())
                }
    }
    
    fileprivate static func updateDatabase(contentsOf parentFolder: File, using contents: [String: Any]) {
        do {
            let files: [[String: Any]] = try contents.value(for: "files")
            let folders: [[String: Any]] = try contents.value(for: "directories")
            
            let createdFiles = try files.map({ try File.createOrUpdate(inContext: CoreDataHelper.managedObjectContext, parentFolder: parentFolder, isDirectory: false, data: $0) })
            let createdFolders = try folders.map({ try File.createOrUpdate(inContext: CoreDataHelper.managedObjectContext, parentFolder: parentFolder, isDirectory: true, data: $0) })
            
            // remove deleted files or folders
            let foundPaths = createdFiles.map({$0.pathString}) + createdFolders.map({$0.pathString})
            let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
            let notOnServerPredicate = NSPredicate(format: "NOT (pathString IN %@)", foundPaths)
            let fetchRequest = NSFetchRequest<File>(entityName: "File")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notOnServerPredicate, parentFolderPredicate])
            
            try CoreDataHelper.delete(fetchRequest: fetchRequest)
        } catch let error {
            log.error(error)
        }
        
        CoreDataHelper.saveContext()
    }
    
    struct SignedUrl: Unmarshaling {
        let url: URL
        
        init(object: MarshaledObject) throws {
            url = try object.value(for: "url")
        }
    }
}
