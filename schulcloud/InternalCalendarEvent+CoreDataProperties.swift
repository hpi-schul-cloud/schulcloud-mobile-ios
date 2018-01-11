//
//  InternalCalendarEvent+CoreDataProperties.swift
//  
//
//  Created by Florian Morel on 11.01.18.
//
//

import Foundation
import CoreData


extension InternalCalendarEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InternalCalendarEvent> {
        return NSFetchRequest<InternalCalendarEvent>(entityName: "InternalCalendarEvent")
    }

    @NSManaged  var id: String
    @NSManaged  var title: String
    @NSManaged  var desc: String
    @NSManaged  var location: String
    @NSManaged  var start: NSDate
    @NSManaged  var end: NSDate
    
    @NSManaged  var rfrequency: String?
    @NSManaged  var rdayOfTheWeek: String?
    @NSManaged  var rendDate: NSDate?
    @NSManaged  var rinterval: Int32
    
    @NSManaged  var course: Course?
}
