//
//  FileHelper.swift
//  schulcloud
//
//  Created by Carl Gödecken on 18.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData
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
    
    static func updateDatabase(contentsOf parentFolder: File, using contents: JSON) {
        
        let fetchRequest = NSFetchRequest<File>(entityName: "File")
        let fileDescription = NSEntityDescription.entity(forEntityName: "File", in: managedObjectContext)!
        var foundPaths = [String]()
        
        // insert or update files
        for fileJson in contents["files"].arrayValue {
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
        for folderJson in contents["directories"].arrayValue {
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
        
        // remove deleted files or folders
        let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
        let notOnServerPredicate = NSPredicate(format: "NOT (pathString in %@)", foundPaths)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notOnServerPredicate, parentFolderPredicate])
        do {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
            try managedObjectContext.execute(deleteRequest)
        } catch let error {
            log.error(error)
        }
        
        saveContext()
    }
}
