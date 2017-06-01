//
//  Content+CoreDataProperties.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData


extension Content {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Content> {
        return NSFetchRequest<Content>(entityName: "Content")
    }

    @NSManaged public var id: String
    @NSManaged public var component: String?
    @NSManaged public var title: String?
    @NSManaged public var text: String?
    @NSManaged public var hidden: Bool
    @NSManaged public var lesson: Lesson?

}
