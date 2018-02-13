//
//  SyncHelper.swift
//  schulcloud
//
//  Created by Max Bothe on 12.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import BrightFutures
import CoreData
import Foundation
import Marshal
import Result

struct SchulcloudSyncStrategy : SyncStrategy {
    var resourceKeyAttribute: String = "_id"

    func queryItems<Query>(forQuery query: Query) -> [URLQueryItem] where Query : ResourceQuery {
        var queryItems: [URLQueryItem] = []

        // includes
        for include in query.includes {
            queryItems.append(URLQueryItem(name: "$populate", value: include))
        }

        // filters
        for (key, value) in query.filters {
            let stringValue = String(describing: value)
            let queryItem = URLQueryItem(name: "filter[\(key)]", value: stringValue)
            queryItems.append(queryItem)
        }

        return queryItems
    }

    func validateResourceData(_ resourceData: MarshalDictionary) -> Result<Void, SyncError> {
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

    func findIncludedObject(forKey key: KeyType, ofObject object: ResourceData, with context: SynchronizationContext) -> FindIncludedObjectResult {
        if let resourceData = try? object.value(for: key) as MarshalDictionary, let resourceId = try? resourceData.value(for: self.resourceKeyAttribute) as String {
            return .object(resourceId, resourceData)
        } else if let resourceId = try? object.value(for: key) as String {
            return .id(resourceId)
        } else {
            return .notExisting
        }
    }

    func findIncludedObjects(forKey key: KeyType, ofObject object: ResourceData, with context: SynchronizationContext) -> FindIncludedObjectsResult {
        if let resourceData = try? object.value(for: key) as [MarshalDictionary] {
            let idsAndObjects: [(id: String, object: ResourceData)] = resourceData.flatMap {
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

}

struct SchulcloudSyncConfig : SyncConfig {

    var baseURL: URL = Constants.backend.url

    var requestHeaders: [String : String] = [
        "Authorization": Globals.account!.accessToken!
    ]

    var persistentContainer: NSPersistentContainer {
        return CoreDataHelper.persistentContainer
    }

    var syncStrategy: SyncStrategy = SchulcloudSyncStrategy()


}

struct SyncHelper {

    static let syncConfiguration = SchulcloudSyncConfig()

    static func syncResources<Resource>(withFetchRequest fetchRequest: NSFetchRequest<Resource>,
                                        withQuery query: MultipleResourcesQuery<Resource>,
                                        deleteNotExistingResources: Bool = true) -> Future<SyncEngine.SyncMultipleResult, SyncError> where Resource: NSManagedObject & Pullable {
        return SyncEngine.syncResources(withFetchRequest: fetchRequest,
                                        withQuery: query,
                                        withConfiguration: self.syncConfiguration,
                                        deleteNotExistingResources: deleteNotExistingResources).onSuccess { syncResult in
            log.info("Successfully merged resources of type: \(Resource.type)")
        }.onFailure { error in
            log.error("Failed to sync resources of type: \(Resource.type) ==> \(error)")
        }
    }

    static func syncResource<Resource>(withFetchRequest fetchRequest: NSFetchRequest<Resource>,
                                       withQuery query: SingleResourceQuery<Resource>) -> Future<SyncEngine.SyncSingleResult, SyncError> where Resource: NSManagedObject & Pullable {
        return SyncEngine.syncResource(withFetchRequest: fetchRequest,
                                       withQuery: query,
                                       withConfiguration: self.syncConfiguration).onSuccess { syncResult in
            log.info("Successfully merged resource of type: \(Resource.type)")
        }.onFailure { error in
            log.error("Failed to sync resource of type: \(Resource.type) ==> \(error)")
        }
    }

    @discardableResult static func saveResource(_ resource: Pushable) -> Future<Void, SyncError> {
        return SyncEngine.saveResource(resource, withConfiguration: self.syncConfiguration).onSuccess { _ in
            log.info("Successfully saved resource of type: \(type(of: resource).type)")
        }.onFailure { error in
            log.error("Failed to save resource of type: \(resource) ==> \(error)")
        }
    }

    @discardableResult static func saveResource(_ resource: Pushable & Pullable) -> Future<Void, SyncError> {
        return SyncEngine.saveResource(resource, withConfiguration: self.syncConfiguration).onSuccess { _ in
            log.info("Successfully saved resource of type: \(type(of: resource).type)")
        }.onFailure { error in
            log.error("Failed to save resource of type: \(resource) ==> \(error)")
        }
    }

    @discardableResult static func deleteResource(_ resource: Pushable & Pullable) -> Future<Void, SyncError> {
        return SyncEngine.deleteResource(resource, withConfiguration: self.syncConfiguration).onSuccess { _ in
            log.info("Successfully deleted resource of type: \(type(of: resource).type)")
        }.onFailure { error in
            log.error("Failed to delete resource: \(resource) ==> \(error)")
        }
    }

}
