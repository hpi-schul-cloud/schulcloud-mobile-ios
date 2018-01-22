//
//  CalendarEvent+.swift
//  schulcloud
//
//  Created by Florian Morel on 11.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData

import Marshal
import DateToolsSwift
import BrightFutures
import DateToolsSwift

extension InternalCalendarEvent {
    
    static func isValidFrequency(remoteString: String) -> Bool {
        switch remoteString {
        case "DAILY":
            return true
        case "WEEKLY":
            return true
        case "MONTHLY":
            return true
        case "YEARLY":
            return true
        default:
            return false
        }
    }
    
    static func isValidDayOfTheWeek(remoteString: String) -> Bool {
        
        switch remoteString {
        case "MO":
            return true
        case "TU":
            return true
        case "WE":
            return true
        case "TH":
            return true
        case "FR":
            return true
        case "SA":
            return true
        case "SU":
            return true
        default:
            return false
        }
    }
    
    static func upsert(inContext context: NSManagedObjectContext, object: MarshaledObject) -> Future<InternalCalendarEvent, SCError> {
        
        do {
            let fetchRequest: NSFetchRequest<InternalCalendarEvent> = InternalCalendarEvent.fetchRequest()
            let id: String = try object.value(for: "id")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let result = try context.fetch(fetchRequest)
            if let event = result.first { return Future(value: event) }
            
            let attributes = try object.value(for: "attributes") as JSONObject
            let included = try? object.value(for: "included") as [JSONObject]
            
            let internalEvent = InternalCalendarEvent(context: context)
            
            internalEvent.id = id
            internalEvent.title = try attributes.value(for: "summary")
            internalEvent.desc = try attributes.value(for: "description")
            internalEvent.location = try attributes.value(for: "location")
            internalEvent.start = (try attributes.value(for: "dtstart") as Date).dateInCurrentTimeZone() as NSDate
            internalEvent.end = (try attributes.value(for: "dtend") as Date).dateInCurrentTimeZone() as NSDate

            if  let includedRules = included,
                let recurringRuleData = includedRules.first(where: { json in
                    return (json["type"] as? String) == "rrule" && (json["id"] as? String) == "\(id)-rrule"
                }) as MarshaledObject? {
                
                let rrattributes = try recurringRuleData.value(for: "attributes") as JSONObject
                
                let frequency: String = try rrattributes.value(for: "freq")
                internalEvent.rfrequency = isValidFrequency(remoteString: frequency) ? frequency : nil
                let dayOfTheWeek: String = try rrattributes.value(for: "wkst")
                internalEvent.rdayOfTheWeek = isValidDayOfTheWeek(remoteString: dayOfTheWeek) ? dayOfTheWeek : nil
                
                internalEvent.rendDate = try? rrattributes.value(for: "until")
                internalEvent.rinterval = try! rrattributes.value(for: "interval") ?? 0
            }
            
            let courseId: String? = try attributes.value(for: "x-sc-courseId")
            let fetchingCourse = internalEvent.fetchCourse(by: courseId, context: context)
            
            return fetchingCourse.onErrorLogAndRecover(with: Void()).flatMap(object: internalEvent)
            
        } catch let error as MarshalError {
            return Future(error: .jsonDeserialization(error.description))
        } catch let error {
            return Future(error: .database(error.localizedDescription))
        }
    }
    
    func fetchCourse(by id: String?, context: NSManagedObjectContext) -> Future<Void, SCError> {
        guard let id = id else { return Future(value: Void() )}
        return Course.fetchQueue.sync {
            return Course.fetch(by: id, inContext: context).flatMap { fetchedCourse -> Future<Void, SCError> in
                self.course = fetchedCourse
                return Future(value: Void() )
            }
        }
    }
}


