//
//  EventData+CoreDataProperties.swift
//  schulcloud
//
//  Created by Max Bothe on 17.08.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData


extension EventData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventData> {
        return NSFetchRequest<EventData>(entityName: "EventData")
    }

    @NSManaged var id: String
    @NSManaged var title: String
    @NSManaged var detail: String
    @NSManaged var location: String
    @NSManaged var start: NSDate
    @NSManaged var end: NSDate
    
    @NSManaged var rrFrequency: String?
    @NSManaged var rrDayOfWeek: String?
    @NSManaged var rrEndDate: NSDate?
    @NSManaged var rrInterval: Int32
    
    @NSManaged var course: Course?
    
    @NSManaged var ekIdentifier: String?
}
