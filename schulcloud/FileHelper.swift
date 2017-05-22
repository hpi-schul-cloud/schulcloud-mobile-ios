//
//  FileHelper.swift
//  schulcloud
//
//  Created by Carl Gödecken on 18.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import BrightFutures
import CoreData
import ObjectMapper
import SwiftyJSON

class FileHelper {
    static var rootUrl: URL {
        let userId = Globals.account?.userId ?? "0"
        return URL(string: "/users/\(userId)/")!
    }
    
    static var rootFolder: File = {
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pathString == %@", rootUrl.absoluteString)
        
        do {
            let result = try managedObjectContext.fetch(fetchRequest)
            if let file = result.first {
                return file
            }
            let file = File(context: managedObjectContext)
            
            file.displayName = "Meine Dateien"
            file.isDirectory = true
            file.pathString = rootUrl.absoluteString
            file.typeString = "directory"
            saveContext()
            return file
        } catch let error {
            fatalError("Unresolved error \(error)") // TODO: replace this with something more friendly
        }
    }()
    
    static func getFolder(withPath path: String) -> File? {
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pathString == %@", path)
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
            "path": file.path.absoluteString.removingPercentEncoding!,
            //"fileType": mime.lookup(file),
            "action": "getObject"
        ]
        let request: Future<SignedUrl, SCError> = ApiHelper.request("fileStorage/signedUrl", method: .post, parameters: parameters, encoding: JSONEncoding.default)
        
        return request.flatMap { signedUrl -> Future<URL, SCError> in
            return Future(value: signedUrl.url)
        }
    }
    static func updateDatabase(forFolder parentFolder: File) -> Future<Void, SCError> {
        let path = "fileStorage?path=\(parentFolder.path.absoluteString)"
        
        return ApiHelper.requestBasic(path)
            .flatMap { response -> Future<Void, SCError> in
                if let data = response.data, data.count > 0 {
                    let json = JSON(data: data)
                    updateDatabase(contentsOf: parentFolder, using: json)
                    return Future(value: Void())
                } else {
                    return Future<Void, SCError>(error: SCError(apiResponse: response.data))
                }
        }
    }
    
    fileprivate static func updateDatabase(contentsOf parentFolder: File, using contents: JSON) {
        
        let fetchRequest = NSFetchRequest<File>(entityName: "File")
        let fileDescription = NSEntityDescription.entity(forEntityName: "File", in: managedObjectContext)!
        var foundPaths = [String]()
        
        guard let files = contents["files"].array,
            let folders = contents["directories"].array else {
                log.error("Could not parse directory contents: \(contents.rawString() ?? "nil")")
                return
        }
        // insert or update files
        for fileJson in files {
            guard let name = fileJson["name"].string else {
                log.error("Could not parse name for \(fileJson)")
                continue
            }
            let path = parentFolder.pathString + name
            foundPaths.append(path)
            
            let pathPredicate = NSPredicate(format: "pathString == %@", path)
            let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pathPredicate, parentFolderPredicate])
            
            do {
                let result = try managedObjectContext.fetch(fetchRequest)
                let file = result.first ?? File(entity: fileDescription, insertInto: managedObjectContext)
                if result.count > 1 {
                    log.error("Found more than one result for \(fetchRequest)")
                }
                
                file.displayName = name
                file.isDirectory = false
                file.pathString = path
                file.typeString = fileJson["type"].stringValue
                file.parentDirectory = parentFolder
                
            } catch let error {
                log.error(error)
            }
        }
        
        // insert or update folders
        for folderJson in folders {
            guard let name = folderJson["name"].string else {
                log.error("Could not parse name for \(folderJson)")
                continue
            }
            let path = parentFolder.pathString + name + "/"
            foundPaths.append(path)
            
            let pathPredicate = NSPredicate(format: "pathString == %@", path)
            let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pathPredicate, parentFolderPredicate])
            
            do {
                let result = try managedObjectContext.fetch(fetchRequest)
                let folder = result.first ?? File(entity: fileDescription, insertInto: managedObjectContext)
                if result.count > 1 {
                    log.error("Found more than one result for \(fetchRequest)")
                }
                
                folder.displayName = name
                folder.isDirectory = true
                folder.pathString = path
                folder.typeString = "directory"
                folder.parentDirectory = parentFolder
                folder.contents = folder.contents ?? NSSet()
                
            } catch let error {
                log.error(error)
            }
        }
        
        saveContext()
        
        // remove deleted files or folders
        let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
        let notOnServerPredicate = NSPredicate(format: "NOT (pathString IN %@)", foundPaths)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notOnServerPredicate, parentFolderPredicate])
        do {
            let result = try managedObjectContext.fetch(fetchRequest)
            print("About to delete " + String(describing: result))
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
            try managedObjectContext.execute(deleteRequest)
        } catch let error {
            log.error(error)
        }
        
        saveContext()
    }
    
    struct SignedUrl: Mappable {
        var url: URL!
        
        init?(map: Map) {
            if map.JSON["url"] == nil {
                return nil
            }
        }
        
        mutating func mapping(map: Map) {
            url   <- (map["url"], URLTransform(shouldEncodeURLString: false))
        }
    }
}
