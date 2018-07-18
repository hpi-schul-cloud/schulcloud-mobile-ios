//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Result
import SyncEngine


protocol SchulcloudSyncStrategy: SyncStrategy {}

extension SchulcloudSyncStrategy {

    func queryItems<Query>(forQuery query: Query) -> [URLQueryItem] where Query: ResourceQuery {
        var queryItems: [URLQueryItem] = []

        // includes
        for include in query.includes {
            queryItems.append(URLQueryItem(name: "$populate", value: include))
        }

        // filters
        for (key, value) in query.filters {
            let stringValue: String
            if let valueArray = value as? [Any] {
                stringValue = valueArray.map { String(describing: $0) }.joined(separator: ",")
            } else if let value = value {
                stringValue = String(describing: value)
            } else {
                stringValue = "null"
            }

            let queryItem = URLQueryItem(name: key, value: stringValue)
            queryItems.append(queryItem)
        }

        return queryItems
    }

    func validateResourceData(_ resourceData: JsonDictionary) -> Result<Void, SyncError> {
        return .success(())
    }

    func validateObjectCreation(object: ResourceData, toHaveType expectedType: String) throws {
        // Nothing to do here
    }

    func extractResourceData(from object: ResourceData) throws -> ResourceData {
        return object
    }

    func extractResourceData(from object: ResourceData) throws -> [ResourceData] {
        return try object.value(for: "data")
    }

    func extractIncludedResourceData(from object: ResourceData) -> [ResourceData] {
        return []
    }

    func findIncludedObject(forKey key: JsonKey, ofObject object: ResourceData, with context: SynchronizationContext) -> FindIncludedObjectResult {
        if let resourceData = try? object.value(for: key) as JsonDictionary,
           let resourceId = try? resourceData.value(for: self.resourceKeyAttribute) as String {
            return .object(resourceId, resourceData)
        } else if let resourceId = try? object.value(for: key) as String {
            return .id(resourceId)
        } else {
            return .notExisting
        }
    }

    func findIncludedObjects(forKey key: JsonKey, ofObject object: ResourceData, with context: SynchronizationContext) -> FindIncludedObjectsResult {
        if let resourceData = try? object.value(for: key) as [JsonDictionary] {
            let idsAndObjects: [(id: String, object: ResourceData)] = resourceData.compactMap {
                guard let resourceId = try? $0.value(for: self.resourceKeyAttribute) as String else { return nil }
                return (id: resourceId, object: $0)
            }

            return .included(objects: idsAndObjects, ids: [])
        } else if let resourceIds = try? object.value(for: key) as [String] {
            return .included(objects: [], ids: resourceIds)
        } else {
            return .notExisting
        }
    }

    func resourceData(for resource: Pushable) -> Result<Data, SyncError> {
        fatalError("This needs to be implemented")
    }

}

struct MainSchulcloudSyncStrategy: SchulcloudSyncStrategy {
    var resourceKeyAttribute: String = "_id"
}

struct CalendarSchulcloudSyncStrategy: SchulcloudSyncStrategy {
    var resourceKeyAttribute: String = "id"
}
