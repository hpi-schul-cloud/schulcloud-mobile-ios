//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData
import DateToolsSwift
import Result

struct CalendarEventHelper {

    static let syncStrategy = CalendarSchulcloudSyncStrategy()

    static func syncEvents() -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = EventData.fetchRequest() as NSFetchRequest<EventData>
        var query = MultipleResourcesQuery(type: EventData.self)
        query.addFilter(forKey: "all", withValue: true)
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query, withStrategy: CalendarEventHelper.syncStrategy)
    }

    static func fetchCalendarEvents(inContext context: NSManagedObjectContext) -> Result<[CalendarEvent], SCError> {
        let fetchRequest: NSFetchRequest<EventData> = EventData.fetchRequest()
        return CoreDataHelper.viewContext.fetchMultiple(fetchRequest).map { eventData in
            return eventData.map { $0.calendarEvent }
        }
    }

}
