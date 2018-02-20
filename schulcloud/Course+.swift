//
//  UserGroup+.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 30.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

//import Foundation
//import CoreData
//import Marshal
//import BrightFutures
//
//extension Course {
//    
//    static let fetchQueue = DispatchQueue.init(label: "course", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
//    
//    static func upsert(data: MarshaledObject, context: NSManagedObjectContext) -> Future<Course, SCError> {
//        do {
//            let course = try self.findOrCreateWithId(data: data, context: context)
//            
//            course.name = try data.value(for: "name")
//            course.schoolId = try data.value(for: "schoolId")
//            course.descriptionText = try data.value(for: "description")
//            course.colorString = try data.value(for: "color")
//            
//            let teacherIds: [String] = (try? data.value(for: "teacherIds")) ?? [String]()
//            return course.fetchTeachers(by: teacherIds, context: context)
//                .onErrorLogAndRecover(with: course)
//        } catch let error {
//            return Future(error: SCError.jsonDeserialization(error.description))
//        }
//    }
//    
//    fileprivate func fetchTeachers(by ids: [String], context: NSManagedObjectContext) -> Future<Course, SCError> {
//        let teacherFutures = ids.map {
//            User.fetch(by: $0, inContext: context)
//        }
//        return teacherFutures.sequence().flatMap { teachers -> Future<Course, SCError> in
//            self.teachers = NSSet(array: teachers)
//            return Future(value: self)
//        }
//    }
//    
//    static func fetch(by id: String, inContext context: NSManagedObjectContext) -> Future<Course, SCError> {
//        if let _course = try? Course.find(by: id, context: context),
//            let course = _course {
//            return Future<Course, SCError>(value: course)
//        }
//        return ApiHelper.request("courses/\(id)").jsonObjectFuture()
//            .flatMap { Course.upsert(data: $0, context: context) }
//    }
//}

//extension Course: IdObject {
//    static let entityName = "Course"
//}

