//
//  File+CoreDataClass.swift
//  schulcloud
//
//  Created by Carl Gödecken on 11.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData
import FileBrowser
import SwiftyJSON

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
}
