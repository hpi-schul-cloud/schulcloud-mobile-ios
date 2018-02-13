//
//  JsonAPISyncStrategy.swift
//  schulcloud
//
//  Created by Max Bothe on 09.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Result
import Marshal

struct JsonAPISyncStrategy: SyncStrategy {

    var resourceKeyAttribute: String {
        return "id"
    }

    func queryItems<Query>(forQuery query: Query) -> [URLQueryItem] where Query : ResourceQuery {
        var queryItems: [URLQueryItem] = []

        // includes
        if !query.includes.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: query.includes.joined(separator: ",")))
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
            let queryItem = URLQueryItem(name: "filter[\(key)]", value: stringValue)
            queryItems.append(queryItem)
        }

        return queryItems
    }

    func validateResourceData(_ resourceData: MarshalDictionary) -> Result<Void, SyncError> {
        // JSON:API validation
        let hasData = resourceData["data"] != nil
        let hasError = resourceData["error"] != nil
        let hasMeta = resourceData["meta"] != nil

        guard hasData || hasError || hasMeta else {
            return .failure(.api(.serialization(.topLevelEntryMissing)))
        }

        guard hasError && !hasData || !hasError && hasData else {
            return .failure(.api(.serialization(.topLevelDataAndErrorsCoexist)))
        }

        guard !hasError else {
            if let errorMessage = resourceData["error"] as? String {
                return .failure(.api(.serverError(message: errorMessage)))
            } else {
                return .failure(.api(.unknownServerError))
            }
        }

        return .success(())
    }

    func validateObjectCreation(object: ResourceData, toHaveType expectedType: String) throws {
        let resourceType = try object.value(for: "type") as String
        if resourceType != expectedType {
            throw SerializationError.resourceTypeMismatch(expected: expectedType, found: resourceType)
        }
    }

    func findIncludedObject(forKey key: KeyType,
                            ofObject object: ResourceData,
                            withAdditionalSyncData additionalSyncData: AdditionalSyncData) -> FindIncludedObjectResult {
        guard let resourceIdentifier = try? object.value(for: "\(key).data") as ResourceIdentifier else {
            return .notExisting
        }

        guard !additionalSyncData.externallyIncludedResourceData.isEmpty else {
            return .id(resourceIdentifier.id)
        }

        let includedResource = additionalSyncData.externallyIncludedResourceData.first { item in
            guard let identifier = try? ResourceIdentifier(object: item) else {
                return false
            }
            return resourceIdentifier.id == identifier.id && resourceIdentifier.type == identifier.type
        }

        guard let resourceData = includedResource else {
            return .id(resourceIdentifier.id)
        }

        return .object(resourceIdentifier.id, resourceData)
    }

    func findIncludedObjects(forKey key: KeyType,
                             ofObject object: ResourceData,
                             withAdditionalSyncData additionalSyncData: AdditionalSyncData) -> FindIncludedObjectsResult {
        guard let resourceIdentifiers = try? object.value(for: "\(key).data") as [ResourceIdentifier] else {
            return .notExisting
        }

        guard !additionalSyncData.externallyIncludedResourceData.isEmpty else {
            return .included(objects: [], ids: resourceIdentifiers.map { $0.id })
        }

        var resourceData: [(id: String, object: ResourceData)] = []
        var resourceIds: [String] = []
        for resourceIdentifier in resourceIdentifiers {
            let includedData = additionalSyncData.externallyIncludedResourceData.first { item in
                guard let identifier = try? ResourceIdentifier(object: item) else {
                    return false
                }
                return resourceIdentifier.id == identifier.id && resourceIdentifier.type == identifier.type
            }

            if let includedResource = includedData {
                resourceData.append((id: resourceIdentifier.id, object: includedResource))
            } else {
                resourceIds.append(resourceIdentifier.id)
            }
        }

        return .included(objects: resourceData, ids: resourceIds)
    }

    func extractResourceData(from object: ResourceData) throws -> ResourceData {
        return try object.value(for: "data")
    }

    func extractResourceData(from object: ResourceData) throws -> [ResourceData] {
        return try object.value(for: "data")
    }

    func extractAdditionalSyncData(from object: ResourceData) -> AdditionalSyncData {
        let includes = try? object.value(for: "included") as [ResourceData]
        return AdditionalSyncData(externallyIncludedResourceData: includes ?? [])
    }

}
