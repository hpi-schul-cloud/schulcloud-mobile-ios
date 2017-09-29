//
//  Homework+CoreDataProperties.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 30.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData


extension Homework {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Homework> {
        return NSFetchRequest<Homework>(entityName: "Homework")
    }

    @NSManaged public var availableDate: NSDate
    @NSManaged public var descriptionText: String
    @NSManaged public var dueDate: NSDate
    @NSManaged public var id: String
    @NSManaged public var isPrivate: Bool
    @NSManaged public var name: String
    @NSManaged public var publicSubmissions: Bool
    @NSManaged public var teacher: User?
    @NSManaged public var course: Course?
    
    /// returns just the day of the due date as yyyy-MM-dd
    public var dueDateShort: String {
        return Homework.shortDateFormatter.string(from: self.dueDate as Date)
    }

}
