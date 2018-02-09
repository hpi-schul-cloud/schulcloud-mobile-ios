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

    func includedDataKey(forAttribute attributeName: String) {
        <#code#>
    }

    func extractResourceData(from object: ResourceData) throws -> ResourceData {
        return try object.value(for: "data")
    }

    func extractResourceData(from object: ResourceData) throws -> [ResourceData] {
        return try object.value(for: "data")
    }

    func extractAdditionalSyncData(from object: ResourceData) -> AddtionalSyncData {
        let includes = try? object.value(for: "included") as [ResourceData]
        return AddtionalSyncData(externallyIncludedResourceData: includes ?? [])
    }

}
