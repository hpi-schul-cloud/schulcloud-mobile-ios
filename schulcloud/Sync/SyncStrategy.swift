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

    // key modification when accessing included data
    func includedDataKey(forAttribute attributeName: String)

    // how to extract data, included (meta)
    // - can throw (marshall)
    // - no default implementation?
    // - for both
    func extractResourceData(from object: ResourceData) throws -> ResourceData
    func extractResourceData(from object: ResourceData) throws -> [ResourceData]
    func extractAdditionalSyncData(from object: ResourceData) -> AddtionalSyncData

}
