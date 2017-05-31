//
//  Homework+CoreDataClass.swift
//  
//
//  Created by Carl Gödecken on 24.05.17.
//
//

import Foundation
import BrightFutures
import CoreData
import Marshal

let context = managedObjectContext

@objc(Homework)
public class Homework: NSManagedObject {
    static let changeNotificationName = "didChangeHomework"
    
    static func upsert(inContext context: NSManagedObjectContext, object: MarshaledObject) -> Future<Homework, SCError> {
        do {            
            let fetchRequest = NSFetchRequest<Homework>(entityName: "Homework")
            let id: String = try object.value(for: "_id")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let result = try context.fetch(fetchRequest)
            let homework = result.first ?? Homework(context: context)
            if result.count > 1 {
                throw SCError.database("Found more than one result for \(fetchRequest)")
            }
            
            homework.id = try object.value(for: "_id")
            homework.name = try object.value(for: "name")
            homework.descriptionText = try object.value(for: "description")
            homework.availableDate = try object.value(for: "availableDate")
            homework.dueDate = try object.value(for: "dueDate")
            homework.publicSubmissions = (try? object.value(for: "publicSubmissions")) ?? false
            homework.isPrivate = (try? object.value(for: "private")) ?? false
            
            if let courseData: MarshalDictionary? = try? object.value(for: "courseId"),
                let unwrapped = courseData {
                homework.course = try Course.upsert(data: unwrapped, context: context)
            }
            let teacherId: String = try object.value(for: "teacherId")
        
        
            return User.fetch(by: teacherId, inContext: context).flatMap { teacher -> Future<Homework, SCError> in
                homework.teacher = teacher
                return Future(value: homework)
            }
        } catch let error as MarshalError {
            return Future(error: .jsonDeserialization(error.description))
        } catch let error {
            return Future(error: .database(error.localizedDescription))
        }
    }
    
}
