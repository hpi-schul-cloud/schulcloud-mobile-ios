//
//  Content+.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 30.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

//import Foundation
//import CoreData
//import Marshal
//
//extension Content {
//    static func upsert(data: MarshaledObject, context: NSManagedObjectContext, containingLesson lesson: Lesson) throws -> Self {
//            let content = try self.findOrCreateWithId(data: data, context: context)
//            
//            content.component = try? data.value(for: "component")
//            content.title = try? data.value(for: "title")
//            content.text = try? data.value(for: "content.text")
//            content.hidden = (try? data.value(for: "hidden")) ?? false
//            content.lesson = lesson
//            
//            return content
//    }
//}

//extension Content: IdObject {
//    static let entityName = "Content"
//}
//
//extension Content {
//    enum ContentType: String {
//        case text
//        case other
//    }
//    
//    var type: ContentType {
//        return ContentType(rawValue: self.component ?? "") ?? .other
//    }
//}

