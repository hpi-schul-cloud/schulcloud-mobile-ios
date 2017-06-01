//
//  UserGroup+.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 30.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData
import Marshal

extension Course {
    static func upsert(data: MarshaledObject, context: NSManagedObjectContext) throws -> Course {
            let course = try self.findOrCreateWithId(data: data, context: context)
            
            course.name = try data.value(for: "name")
            course.schoolId = try data.value(for: "schoolId")
            course.descriptionText = try data.value(for: "description")
            course.colorString = try data.value(for: "color")
            
            return course
    }
}

extension Course: IdObject {}
