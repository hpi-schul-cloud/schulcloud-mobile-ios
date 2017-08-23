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

    @NSManaged public var externalEventId: String
    @NSManaged public var courseId: String?
    @NSManaged public var eventId: String

}
