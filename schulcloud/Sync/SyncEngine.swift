//
//  SyncEngine.swift
//  schulcloud
//
//  Created by Max Bothe on 30.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import Result
import CoreData
import Marshal

struct SyncEngine {

    struct SyncMultipleResult {
        let objectIds: [NSManagedObjectID]
        let headers: [AnyHashable: Any]
    }

    struct SyncSingleResult {
        let objectId: NSManagedObjectID
        let headers: [AnyHashable: Any]
    }

    private struct MergeMultipleResult<Resource> where Resource: NSManagedObject & Pullable {
        let resources: [Resource]
        let headers: [AnyHashable: Any]
    }

    private struct MergeSingleResult<Resource> where Resource: NSManagedObject & Pullable {
        let resource: Resource
        let headers: [AnyHashable: Any]
    }

    private struct NetworkResult {
        let resourceData: ResourceData
        let headers: [AnyHashable: Any]
    }

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 300
        if #available(iOS 11, *) {
            configuration.waitsForConnectivity = true
        }
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

    // MARK: - build url request

    private static func buildGetRequest<Query>(forQuery query: Query, withConfiguration configuration: SyncConfig) -> Result<URLRequest, SyncError> where Query: ResourceQuery {
        guard let resourceUrl = query.resourceURL(relativeTo: configuration.baseURL) else {
            return .failure(.invalidResourceURL)
        }

        guard var urlComponents = URLComponents(url: resourceUrl, resolvingAgainstBaseURL: true) else {
            return .failure(.invalidURLComponents(resourceUrl))
        }

        urlComponents.queryItems = configuration.syncStrategy.queryItems(forQuery: query)

        guard let url = urlComponents.url else {
            return .failure(.invalidURL(urlComponents.url?.absoluteString))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        for (header, value) in configuration.requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        return .success(request)
    }

    enum SaveRequestMethod: String {
        case post = "POST"
        case patch = "PATCH"
    }

    private static func buildSaveRequest(forQuery query: ResourceURLRepresentable,
                                         withHTTPMethod httpMethod: SaveRequestMethod,
                                         forResource resource: Pushable,
                                         withConfiguration configuration: SyncConfig) -> Result<URLRequest, SyncError> {

        guard let resourceUrl = query.resourceURL(relativeTo: configuration.baseURL) else {
            return .failure(.invalidResourceURL)
        }

        var request = URLRequest(url: resourceUrl)
        request.httpMethod = httpMethod.rawValue

        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        for (header, value) in configuration.requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        return resource.resourceData().map { data in
            request.httpBody = data
            return request
        }
    }

    private static func buildDeleteRequest(forQuery query: RawSingleResourceQuery,
                                           withConfiguration configuration: SyncConfig) -> Result<URLRequest, SyncError> {
        guard let resourceUrl = query.resourceURL(relativeTo: configuration.baseURL) else {
            return .failure(.invalidResourceURL)
        }

        var request = URLRequest(url: resourceUrl)
        request.httpMethod = "DELETE"

        for (header, value) in configuration.requestHeaders {
            request.setValue(value, forHTTPHeaderField: header)
        }

        return .success(request)
    }


    // MARK: - core data operation

    private static func fetchCoreDataObjects<Resource>(withFetchRequest fetchRequest: NSFetchRequest<Resource>, inContext context: NSManagedObjectContext) -> Future<[Resource], SyncError> where Resource: NSManagedObject & Pullable {
        do {
            let objects = try context.fetch(fetchRequest)
            return Future(value: objects)
        } catch {
            return Future(error: .coreData(error))
        }
    }

    private static func fetchCoreDataObject<Resource>(withFetchRequest fetchRequest: NSFetchRequest<Resource>, inContext context: NSManagedObjectContext) -> Future<Resource?, SyncError> where Resource: NSManagedObject & Pullable {
        do {
            let objects = try context.fetch(fetchRequest)
            return Future(value: objects.first)
        } catch {
            return Future(error: .coreData(error))
        }
    }

    private static func doNetworkRequest(_ request: URLRequest, withConfiguration configuration: SyncConfig) -> Future<NetworkResult, SyncError> {
        let promise = Promise<NetworkResult, SyncError>()

        let task = self.session.dataTask(with: request) { (data, response, error) in
            if let err = error {
                promise.failure(.network(err))
                return
            }

            guard let urlResponse = response as? HTTPURLResponse else {
                promise.failure(.api(.invalidResponse))
                return
            }

            guard 200 ... 299 ~= urlResponse.statusCode else {
                promise.failure(.api(.response(statusCode: urlResponse.statusCode, headers: urlResponse.allHeaderFields)))
                return
            }

            guard let responseData = data else {
                promise.failure(.api(.noData))
                return
            }

            do {
                guard let resourceData = try JSONSerialization.jsonObject(with: responseData, options: []) as? MarshalDictionary else {
                    promise.failure(.api(.serialization(.invalidDocumentStructure)))
                    return
                }

                switch configuration.syncStrategy.validateResourceData(resourceData) {
                case .success(_):
                    let result = NetworkResult(resourceData: resourceData, headers: urlResponse.allHeaderFields)
                    promise.success(result)
                case let .failure(error):
                    promise.failure(error)
                }
            } catch {
                promise.failure(.api(.serialization(.jsonSerialization(error))))
            }
        }

        configuration.networkActivity(withType: .start)
        task.resume()
        return promise.future.onComplete { _ in
            configuration.networkActivity(withType: .stop)
        }
    }

    // MARK: - merge

    private static func mergeResources<Resource>(object: ResourceData,
                                                 withExistingObjects objects: [Resource],
                                                 deleteNotExistingResources: Bool,
                                                 inContext context: NSManagedObjectContext,
                                                 withSyncStrategy syncStrategy: SyncStrategy) -> Future<[Resource], SyncError> where Resource: NSManagedObject & Pullable {
        do {
            var existingObjects = objects
            var newObjects: [Resource] = []
//            let dataArray = try object.value(for: "data") as [ResourceData]
//            let includes = try? object.value(for: "included") as [ResourceData]

            let dataArray = try syncStrategy.extractResourceData(from: object) as [ResourceData]
            let additionalSyncData = syncStrategy.extractAdditionalSyncData(from: object)

            for data in dataArray {
                let id = try data.value(for: "id") as String
                if var existingObject = existingObjects.first(where: { $0.id == id }) {
                    try existingObject.update(withObject: data, withAdditionalSyncData: additionalSyncData, inContext: context)
                    if let index = existingObjects.index(of: existingObject) {
                        existingObjects.remove(at: index)
                    }
                    newObjects.append(existingObject)
                } else {
                    if var fetchedResource = try self.findExistingResource(withId: id, ofType: Resource.self, inContext: context) {
                        try fetchedResource.update(withObject: data, withAdditionalSyncData: additionalSyncData, inContext: context)
                        newObjects.append(fetchedResource)
                    } else {
                        let newObject = try Resource.value(from: data, withAdditionalSyncData: additionalSyncData, inContext: context)
                        newObjects.append(newObject)
                    }
                }
            }

            if deleteNotExistingResources {
                for existingObject in existingObjects {
                    context.delete(existingObject)
                }
            }

            return Future(value: newObjects)
        } catch let error as MarshalError {
            return Future(error: .api(.serialization(.modelDeserialization(error, onType: Resource.type))))
        } catch let error as NestedMarshalError {
            return Future(error: .api(.serialization(.modelDeserialization(error, onType: Resource.type))))
        } catch let error as SynchronizationError {
            return Future(error: .synchronization(error))
        } catch {
            return Future(error: .unknown(error))
        }
    }

    private static func mergeResource<Resource>(object: ResourceData,
                                                withExistingObject existingObject: Resource?,
                                                inContext context: NSManagedObjectContext,
                                                withSyncStrategy syncStrategy: SyncStrategy) -> Future<Resource, SyncError> where Resource: NSManagedObject & Pullable {
        do {
            let newObject: Resource
//            let data = try object.value(for: "data") as ResourceData
//            let includes = try? object.value(for: "included") as [ResourceData]
            let data = try syncStrategy.extractResourceData(from: object) as ResourceData
            let additionalSyncData = syncStrategy.extractAdditionalSyncData(from: object)

            let id = try data.value(for: "id") as String

            if var existingObject = existingObject {
                if existingObject.id == id {
                    try existingObject.update(withObject: data, withAdditionalSyncData: additionalSyncData, inContext: context)
                    newObject = existingObject
                } else {
                    newObject = try Resource.value(from: data, withAdditionalSyncData: additionalSyncData, inContext: context)
                }
            } else {
                if var fetchedResource = try self.findExistingResource(withId: id, ofType: Resource.self, inContext: context) {
                    try fetchedResource.update(withObject: data, withAdditionalSyncData: additionalSyncData, inContext: context)
                    newObject = fetchedResource
                } else {
                    newObject = try Resource.value(from: data, withAdditionalSyncData: additionalSyncData, inContext: context)
                }
            }

            return Future(value: newObject)
        } catch let error as MarshalError {
            return Future(error: .api(.serialization(.modelDeserialization(error, onType: Resource.type))))
        } catch let error as SynchronizationError {
            return Future(error: .synchronization(error))
        } catch {
            return Future(error: .unknown(error))
        }
    }

    // MARK: - sync

    static func syncResources<Resource>(withFetchRequest fetchRequest: NSFetchRequest<Resource>,
                                        withQuery query: MultipleResourcesQuery<Resource>,
                                        withConfiguration configuration: SyncConfig,
                                        deleteNotExistingResources: Bool = true) -> Future<SyncMultipleResult, SyncError> where Resource: NSManagedObject & Pullable {
        let promise = Promise<SyncMultipleResult, SyncError>()

        configuration.persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            let coreDataFetch = self.fetchCoreDataObjects(withFetchRequest: fetchRequest, inContext: context)
            let networkRequest = self.buildGetRequest(forQuery: query, withConfiguration: configuration).flatMap { request in
                return retry(ImmediateExecutionContext, times: 5, coolDown: DispatchTimeInterval.seconds(2)) {
                    return self.doNetworkRequest(request, withConfiguration: configuration)
                }
            }

            coreDataFetch.zip(networkRequest).flatMap(ImmediateExecutionContext) { objects, networkResult in
                return self.mergeResources(object: networkResult.resourceData,
                                           withExistingObjects: objects,
                                           deleteNotExistingResources: deleteNotExistingResources,
                                           inContext: context,
                                           withSyncStrategy: configuration.syncStrategy).map { resources in
                    return MergeMultipleResult(resources: resources, headers: networkResult.headers)
                }
            }.inject(ImmediateExecutionContext) {
                do {
                    try context.save()
                    return Future(value: ())
                } catch {
                    return Future(error: .coreData(error))
                }
            }.map(ImmediateExecutionContext) { mergeResult in
                return SyncMultipleResult(objectIds: mergeResult.resources.map { $0.objectID }, headers: mergeResult.headers)
            }.onComplete(ImmediateExecutionContext) { result in
                promise.complete(result)
            }
        }

        return promise.future
    }

    static func syncResource<Resource>(withFetchRequest fetchRequest: NSFetchRequest<Resource>,
                                       withQuery query: SingleResourceQuery<Resource>,
                                       withConfiguration configuration: SyncConfig) -> Future<SyncSingleResult, SyncError> where Resource: NSManagedObject & Pullable {
        let promise = Promise<SyncSingleResult, SyncError>()

        configuration.persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            let coreDataFetch = self.fetchCoreDataObject(withFetchRequest: fetchRequest, inContext: context)
            let networkRequest = self.buildGetRequest(forQuery: query, withConfiguration: configuration).flatMap { request in
                return retry(ImmediateExecutionContext, times: 5, coolDown: DispatchTimeInterval.seconds(2)) {
                    return self.doNetworkRequest(request, withConfiguration: configuration)
                }
            }

            coreDataFetch.zip(networkRequest).flatMap(ImmediateExecutionContext) { object, networkResult -> Future<MergeSingleResult<Resource>, SyncError> in
                return self.mergeResource(object: networkResult.resourceData,
                                          withExistingObject: object,
                                          inContext: context,
                                          withSyncStrategy: configuration.syncStrategy).map { resource in
                    return MergeSingleResult(resource: resource, headers: networkResult.headers)
                }
            }.inject(ImmediateExecutionContext) {
                do {
                    try context.save()
                    return Future(value: ())
                } catch {
                    return Future(error: .coreData(error))
                }
            }.map(ImmediateExecutionContext) { mergeResult in
                return SyncSingleResult(objectId: mergeResult.resource.objectID, headers: mergeResult.headers)
            }.onComplete(ImmediateExecutionContext) { result in
                promise.complete(result)
            }
        }

        return promise.future
    }

    // MARK: - saving

    @discardableResult static func saveResource(_ resource: Pushable, withConfiguration configuration: SyncConfig) -> Future<Void, SyncError> {
        let resourceType = type(of: resource).type
        let query = RawMultipleResourcesQuery(type: resourceType)
        let networkRequest = self.buildSaveRequest(forQuery: query, withHTTPMethod: .post, forResource: resource, withConfiguration: configuration).flatMap { request in
            return self.doNetworkRequest(request, withConfiguration: configuration)
        }

        return networkRequest.asVoid()
    }

    @discardableResult static func saveResource(_ resource: Pushable & Pullable, withConfiguration configuration: SyncConfig) -> Future<Void, SyncError> {
        let resourceType = type(of: resource).type
        let urlRequest: Result<URLRequest, SyncError>
        if resource.objectState == .new {
            let query = RawMultipleResourcesQuery(type: resourceType)
            urlRequest = self.buildSaveRequest(forQuery: query, withHTTPMethod: .post, forResource: resource, withConfiguration: configuration)
        } else {
            let query = RawSingleResourceQuery(type: resourceType, id: resource.id)
            urlRequest = self.buildSaveRequest(forQuery: query, withHTTPMethod: .patch, forResource: resource, withConfiguration: configuration)
        }

        let networkRequest = urlRequest.flatMap { request in
            return self.doNetworkRequest(request, withConfiguration: configuration)
        }

        return networkRequest.asVoid()
    }

    // MARK: - deleting

    @discardableResult static func deleteResource(_ resource: Pushable & Pullable, withConfiguration configuration: SyncConfig) -> Future<Void, SyncError> {
        let resourceType = type(of: resource).type
        let query = RawSingleResourceQuery(type: resourceType, id: resource.id)
        let networkRequest = self.buildDeleteRequest(forQuery: query, withConfiguration: configuration).flatMap { request in
            return self.doNetworkRequest(request, withConfiguration: configuration)
        }

        return networkRequest.asVoid()
    }

    static func findExistingResource<Resource>(withId objectId: String,
                                               ofType type: Resource.Type,
                                               inContext context: NSManagedObjectContext) throws -> Resource? where Resource: NSManagedObject & Pullable {
        guard let entityName = Resource.entity().name else {
            throw SynchronizationError.missingEnityNameForResource(Resource.self)
        }

        let fetchRequest: NSFetchRequest<Resource> = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "id = %@", objectId)

        let objects = try context.fetch(fetchRequest)

        if objects.count > 1 {
            log.warning("Found multiple resources while updating relationship (entity name: \(entityName), \(objectId))")
        }

        return objects.first
    }

}
