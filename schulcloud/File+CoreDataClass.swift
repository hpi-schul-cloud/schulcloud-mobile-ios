//
//  File+CoreDataClass.swift
//  schulcloud
//
//  Created by Carl Gödecken on 11.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData
import Marshal

@objc(File)
public class File: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }
    
    @NSManaged public var cacheUrlString: String?
    @NSManaged public var displayName: String
    @NSManaged public var isDirectory: Bool
    @NSManaged public var pathString: String
    @NSManaged public var typeString: String
    @NSManaged public var size: NSNumber?
    @NSManaged public var parentDirectory: File?
    @NSManaged public var contents: NSSet?
    
}

// MARK: Generated accessors for contents
extension File {
    
    @objc(addContentsObject:)
    @NSManaged public func addToContents(_ value: File)
    
    @objc(removeContentsObject:)
    @NSManaged public func removeFromContents(_ value: File)
    
    @objc(addContents:)
    @NSManaged public func addToContents(_ values: NSSet)
    
    @objc(removeContents:)
    @NSManaged public func removeFromContents(_ values: NSSet)
    
}

extension File {
    static func createOrUpdate(inContext context: NSManagedObjectContext, parentFolder: File, isDirectory: Bool, data: MarshaledObject) throws -> File {
        let name: String = try data.value(for: "name")
        let path = parentFolder.pathString + name + (isDirectory ? "/" : "")
        
        let fetchRequest = NSFetchRequest<File>(entityName: "File")
        let fileDescription = NSEntityDescription.entity(forEntityName: "File", in: context)!
        let pathPredicate = NSPredicate(format: "pathString == %@", path)
        let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pathPredicate, parentFolderPredicate])
        
        let result = try context.fetch(fetchRequest)
        let file = result.first ?? File(entity: fileDescription, insertInto: context)
        if result.count > 1 {
            throw SCError.database("Found more than one result for \(fetchRequest)")
        }
        
        file.displayName = name
        file.isDirectory = isDirectory
        file.pathString = path
        file.typeString = isDirectory ? "directory" : try data.value(for: "type")
        if let size = try? data.value(for: "size") as Int64 {
            file.size = size as NSNumber?
        }
        file.parentDirectory = parentFolder
        
        return file
    }
}

// MARK: computed properties
extension File {
    
    var path: URL {
        get {
            let encoded = pathString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            return URL(string: encoded)!
        }
        set {
            self.pathString = newValue.absoluteString
        }
    }
    
    var cacheUrl: URL? {
        get {
            guard let urlString = cacheUrlString else { return nil }
            return URL(string: urlString)!
        }
        set {
            cacheUrlString = newValue?.absoluteString
        }
    }

    var detail: String? {
        guard !self.isDirectory else {
            return nil
        }

        guard let size = self.size else {
            return nil
        }

        return ByteCountFormatter.string(fromByteCount: Int64(truncating: size), countStyle: .binary)
    }
}
