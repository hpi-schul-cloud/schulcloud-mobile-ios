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

final class File: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }
    
    @NSManaged public var id: String
    @NSManaged public var cacheURL_: String?
    @NSManaged public var name: String
    @NSManaged public var isDirectory: Bool
    @NSManaged public var currentPath: String
    @NSManaged public var mimeType: String?
    @NSManaged public var size: NSNumber?
    @NSManaged public var parentDirectory: File?
    @NSManaged public var contents: Set<File>
    @NSManaged public var permissions_: Int64
    
}

extension File {
    
    struct Permissions : OptionSet {
        let rawValue: Int64

        static let read = Permissions(rawValue: 1 << 1)
        static let write = Permissions(rawValue: 1 << 2)
        
        static let read_write : Permissions = [.read, .write]
        
        init(rawValue: Int64) {
            self.rawValue = rawValue
        }
        
        init?(str: String) {
            switch str {
            case "can_read":
                self = Permissions.read
            case "can_write":
                self = Permissions.write
            default:
                return nil
            }
        }
        
        init(json: MarshaledObject) throws {
            let fetchedPersmissions: [String] = try json.value(for: "permissions")
            let permissions : [Permissions] = fetchedPersmissions.flatMap { Permissions(str:$0) }
            self.rawValue =  permissions.reduce([], { (acc, permission) -> Permissions in
                return acc.union(permission)
            }).rawValue
        }
    }
    
    var permissions : Permissions {
        get {
            return Permissions(rawValue: self.permissions_)
        }
        set {
            self.permissions_ = newValue.rawValue
        }
    }
}

extension File {

    static func createOrUpdate(inContext context: NSManagedObjectContext, parentFolder: File, isDirectory: Bool, data: MarshaledObject) throws -> File {
        let name: String = try data.value(for: "name")
        let path = parentFolder.url.appendingPathComponent(name, isDirectory: isDirectory)
        
        let fetchRequest = NSFetchRequest<File>(entityName: "File")
        let pathPredicate = NSPredicate(format: "currentPath == %@", path.absoluteString)
        let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pathPredicate, parentFolderPredicate])
        
        let result = try context.fetch(fetchRequest)
        let file = result.first ?? File(context: context)
        if result.count > 1 {
            throw SCError.database("Found more than one result for \(fetchRequest)")
        }
        
        file.id = try data.value(for: "_id")
        file.name = name
        file.isDirectory = isDirectory
        file.currentPath = path.absoluteString
        file.mimeType = try data.value(for: "type") ?? nil
        if let size = try? data.value(for: "size") as Int64 {
            file.size = size as NSNumber?
        }
        file.parentDirectory = parentFolder
        
        let permissionsObject : [MarshaledObject]? = try? data.value(for: "permissions")
        let userPermission: MarshaledObject? = permissionsObject?.first { (data) -> Bool in
            if let userId: String = try? data.value(for: "userId"),
                userId == Globals.account?.userId { //find permission for current user
                return true
            }
            return false
        }
        if let userPermission = userPermission {
            file.permissions = try Permissions(json: userPermission)
        }

        return file
    }
}

// MARK: computed properties
extension File {
    
    var url: URL {
        get {
            return URL(string: currentPath)!
        }
        set {
            self.currentPath = newValue.absoluteString
        }
    }
    
    var cacheUrl: URL? {
        get {
            guard let urlString = cacheURL_ else { return nil }
            return URL(string: urlString)!
        }
        set {
            cacheURL_ = newValue?.absoluteString
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
