//
//  EventData+.swift
//  schulcloud
//
//  Created by Florian Morel on 23.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData

import Marshal
import DateToolsSwift
import BrightFutures
import DateToolsSwift

extension EventData {
    
    static func isValidFrequency(remoteString: String) -> Bool {
        return ["DAILY","WEEKLY","MONTHLY","YEARLY"].contains(remoteString)
    }
    
    static func isValidDayOfTheWeek(remoteString: String) -> Bool {
        return ["MO","TU","WE","TH","FR","SA","SU"].contains(remoteString)
    }
    
    static func upsert(inContext context: NSManagedObjectContext, object: MarshaledObject) -> Future<EventData, SCError> {
        do {
            let fetchRequest: NSFetchRequest<EventData> = EventData.fetchRequest()
            let id: String = try object.value(for: "id")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let result = try context.fetch(fetchRequest)
            if let event = result.first { return Future(value: event) }
            
            let attributes = try object.value(for: "attributes") as JSONObject
            let included = try? object.value(for: "included") as [JSONObject]
            
            let eventData = EventData(context: context)
            
            eventData.id = id
            eventData.title = try attributes.value(for: "summary")
            eventData.detail = try attributes.value(for: "description")
            eventData.location = try attributes.value(for: "location")
            eventData.start = (try attributes.value(for: "dtstart") as Date).dateInCurrentTimeZone() as NSDate
            eventData.end = (try attributes.value(for: "dtend") as Date).dateInCurrentTimeZone() as NSDate
            
            if  let includedRules = included,
                let recurringRuleData = includedRules.first(where: { json in
                    return (json["type"] as? String) == "rrule" && (json["id"] as? String) == "\(id)-rrule"
                }) as MarshaledObject? {
                
                let rrattributes = try recurringRuleData.value(for: "attributes") as JSONObject
                
                let frequency: String = try rrattributes.value(for: "freq")
                eventData.rrFrequency = isValidFrequency(remoteString: frequency) ? frequency : nil
                let dayOfTheWeek: String = try rrattributes.value(for: "wkst")
                eventData.rrDayOfWeek = isValidDayOfTheWeek(remoteString: dayOfTheWeek) ? dayOfTheWeek : nil
                
                eventData.rrEndDate = try? rrattributes.value(for: "until")
                
                eventData.rrInterval = 1
                if let interval: Int32 = try? rrattributes.value(for: "interval") {
                    eventData.rrInterval = interval > 0 ? interval : 1
                }
            }
            
            let courseId: String? = try attributes.value(for: "x-sc-courseId")
            let fetchingCourse = eventData.fetchCourse(by: courseId, context: context)
            
            return fetchingCourse.onErrorLogAndRecover(with: Void()).flatMap(object: eventData)
            
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
