//
//  SyncStrategy.swift
//  schulcloud
//
//  Created by Max Bothe on 08.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Result
import Marshal

protocol SyncStrategy {

    var resourceKeyAttribute: String { get }

    func queryItems<Query>(forQuery query: Query) -> [URLQueryItem] where Query: ResourceQuery 
    func validateResourceData(_ resourceData: MarshalDictionary) -> Result<Void, SyncError>
    func validateObjectCreation(object: ResourceData, toHaveType expectedType: String) throws

    // how to extract data, included (meta)
    // - can throw (marshall)
    // - no default implementation?
    // - for both
    func extractResourceData(from object: ResourceData) throws -> ResourceData
    func extractResourceData(from object: ResourceData) throws -> [ResourceData]
    func extractAdditionalSyncData(from object: ResourceData) -> AdditionalSyncData

    func findIncludedObject(forKey key: KeyType,
                            ofObject object: ResourceData,
                            withAdditionalSyncData additionalSyncData: AdditionalSyncData) -> FindIncludedObjectResult

    func findIncludedObjects(forKey key: KeyType,
                             ofObject object: ResourceData,
                             withAdditionalSyncData additionalSyncData: AdditionalSyncData) -> FindIncludedObjectsResult



}

enum FindIncludedObjectResult {
    case notExisting
    case id(String)
    case object(String, ResourceData)
}

enum FindIncludedObjectsResult {
    case notExisting
    case included(objects: [(id: String, object: ResourceData)], ids: [String])
}
