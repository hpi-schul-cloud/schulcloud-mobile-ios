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

    func resourceData(for resource: Pushable) -> Result<Data, SyncError> {
        fatalError("This needs to be implmented")
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

}

struct SyncHelper {

    static let syncConfiguration = SchulcloudSyncConfig()
    static let syncStrategy: SyncStrategy = SchulcloudSyncStrategy()

    static func syncResources<Resource>(withFetchRequest fetchRequest: NSFetchRequest<Resource>,
                                        withQuery query: MultipleResourcesQuery<Resource>,
                                        withConfiguration configuration: SyncConfig = SyncHelper.syncConfiguration,
                                        withStrategy strategy: SyncStrategy = SyncHelper.syncStrategy,
                                        deleteNotExistingResources: Bool = true) -> Future<SyncEngine.SyncMultipleResult, SCError> where Resource: NSManagedObject & Pullable {
        return SyncEngine.syncResources(withFetchRequest: fetchRequest,
                                        withQuery: query,
                                        withConfiguration: configuration,
                                        withStrategy: strategy,
                                        deleteNotExistingResources: deleteNotExistingResources).mapError { syncError -> SCError in
            return .synchronization(syncError)
        }.onSuccess { syncResult in
            log.info("Successfully merged resources of type: \(Resource.type)")
        }.onFailure { error in
            log.error("Failed to sync resources of type: \(Resource.type) ==> \(error)")
        }
    }

    static func syncResource<Resource>(withFetchRequest fetchRequest: NSFetchRequest<Resource>,
                                       withQuery query: SingleResourceQuery<Resource>,
                                       withConfiguration configuration: SyncConfig = SyncHelper.syncConfiguration,
                                       withStrategy strategy: SyncStrategy = SyncHelper.syncStrategy) -> Future<SyncEngine.SyncSingleResult, SCError> where Resource: NSManagedObject & Pullable {
        return SyncEngine.syncResource(withFetchRequest: fetchRequest,
                                       withQuery: query,
                                       withConfiguration: configuration,
                                       withStrategy: strategy).mapError { syncError -> SCError in
            return .synchronization(syncError)
        }.onSuccess { syncResult in
            log.info("Successfully merged resource of type: \(Resource.type)")
        }.onFailure { error in
            log.error("Failed to sync resource of type: \(Resource.type) ==> \(error)")
        }
    }

    @discardableResult static func createResource<Resource>(ofType resourceType: Resource.Type,
                                                            withData resourceData: Data,
                                                            withConfiguration configuration: SyncConfig = SyncHelper.syncConfiguration,
                                                            withStrategy strategy: SyncStrategy = SyncHelper.syncStrategy) -> Future<SyncEngine.SyncSingleResult, SCError> where Resource: NSManagedObject & Pullable & Pushable {
        return SyncEngine.createResource(ofType: resourceType,
                                         withData: resourceData,
                                         withConfiguration: configuration,
                                         withStrategy: strategy).mapError { syncError -> SCError in
            return .synchronization(syncError)
        }.onSuccess { _ in
            log.info("Successfully created resource of type: \(resourceType)")
        }.onFailure { error in
            log.error("Failed to create resource of type: \(resourceType) ==> \(error)")
        }
    }

    @discardableResult static func createResource(_ resource: Pushable,
                                                  withConfiguration configuration: SyncConfig = SyncHelper.syncConfiguration,
                                                  withStrategy strategy: SyncStrategy = SyncHelper.syncStrategy) -> Future<Void, SCError> {
        return SyncEngine.createResource(resource,
                                         withConfiguration: configuration,
                                         withStrategy: strategy).mapError { syncError -> SCError in
            return .synchronization(syncError)
        }.onSuccess { _ in
            log.info("Successfully created resource of type: \(type(of: resource).type)")
        }.onFailure { error in
            log.error("Failed to create resource of type: \(resource) ==> \(error)")
        }
    }

    @discardableResult static func saveResource(_ resource: Pullable & Pushable,
                                                withConfiguration configuration: SyncConfig = SyncHelper.syncConfiguration,
                                                withStrategy strategy: SyncStrategy = SyncHelper.syncStrategy) -> Future<Void, SCError> {
        return SyncEngine.saveResource(resource,
                                       withConfiguration: configuration,
                                       withStrategy: strategy).mapError { syncError -> SCError in
            return .synchronization(syncError)
        }.onSuccess { _ in
            log.info("Successfully saved resource of type: \(type(of: resource).type)")
        }.onFailure { error in
            log.error("Failed to save resource of type: \(resource) ==> \(error)")
        }
    }

    @discardableResult static func deleteResource(_ resource: Pushable & Pullable,
                                                  withConfiguration configuration: SyncConfig = SyncHelper.syncConfiguration,
                                                  withStrategy strategy: SyncStrategy = SyncHelper.syncStrategy) -> Future<Void, SCError> {
        return SyncEngine.deleteResource(resource,
                                         withConfiguration: configuration,
                                         withStrategy: strategy).mapError { syncError -> SCError in
            return .synchronization(syncError)
        }.onSuccess { _ in
            log.info("Successfully deleted resource of type: \(type(of: resource).type)")
        }.onFailure { error in
            log.error("Failed to delete resource: \(resource) ==> \(error)")
        }
    }

}
