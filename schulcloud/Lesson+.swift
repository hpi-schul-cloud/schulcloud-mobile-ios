//
//  Lesson+.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 30.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData
import Marshal

extension Lesson {
    static func upsert(data: MarshaledObject, context: NSManagedObjectContext) throws -> Lesson {
            let lesson = try self.findOrCreateWithId(data: data, context: context)
            
            lesson.name = try? data.value(for: "name")
            lesson.descriptionString = try? data.value(for: "description")
            lesson.date = try? data.value(for: "date")
            
            let contentData: [MarshaledObject] = (try? data.value(for: "contents")) ?? [MarshaledObject]()
            let contents = try contentData.map{ try Content.upsert(data: $0, context: context, containingLesson: lesson) }
            lesson.contents = NSSet(array: contents)
            
            let courseId: String = try data.value(for: "courseId")
            lesson.course = try Course.find(by: courseId, context: context)
            
            return lesson
    }
}

extension Lesson: IdObject {}
