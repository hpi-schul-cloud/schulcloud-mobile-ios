//
//  Homework+CoreDataClass.swift
//  
//
//  Created by Carl Gödecken on 24.05.17.
//
//

import Foundation
import CoreData
import Marshal

let context = managedObjectContext

@objc(Homework)
public class Homework: NSManagedObject, Unmarshaling {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Homework> {
        return NSFetchRequest<Homework>(entityName: "Homework")
    }
    
    @NSManaged public var id: String
    @NSManaged public var teacherId: String // TODO: convert to relationship
    @NSManaged public var name: String
    @NSManaged public var descriptionText: String
    @NSManaged public var availableDate: NSDate
    @NSManaged public var dueDate: NSDate
    @NSManaged public var publicSubmissions: Bool
    @NSManaged public var courseId: String? // TODO: convert to relationship
    @NSManaged public var isPrivate: Bool
    
    convenience required public init(object: MarshaledObject) throws {
        let description = NSEntityDescription.entity(forEntityName: "Homework", in: context)!
        self.init(entity: description, insertInto: context)
        id = try object.value(for: "_id")
        teacherId = try object.value(for: "teacherId")
        name = try object.value(for: "name")
        descriptionText = try object.value(for: "description")
        availableDate = try object.value(for: "availableDate")
        dueDate = try object.value(for: "dueDate")
        publicSubmissions = (try? object.value(for: "publicSubmissions")) ?? false
        courseId = try? object.value(for: "courseId")
        isPrivate = try object.value(for: "private")
    }
    
}
