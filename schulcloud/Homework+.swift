//
//  Homework+.swift
//  schulcloud
//
//  Created by Max Bothe on 05.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData
import Marshal

extension Homework {

    static let homeworkDidChangeNotificationName = "didChangeHomework"

    static let teacherFetchQueue = DispatchQueue.init(label: "homeworkTeacher", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    static let courseFetchQueue = DispatchQueue.init(label: "homeworkCourse", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)

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
                try courseFetchQueue.sync {
                    homework.course = try Course.upsert(data: unwrapped, context: context)
                }
            }
            let teacherId: String = try object.value(for: "teacherId")

            return teacherFetchQueue.sync {
                return User.fetch(by: teacherId, inContext: context).flatMap { teacher -> Future<Homework, SCError> in
                    homework.teacher = teacher
                    return Future(value: homework)
                }
            }
        } catch let error as MarshalError {
            return Future(error: .jsonDeserialization(error.description))
        } catch let error {
            return Future(error: .database(error.localizedDescription))
        }
    }

}
