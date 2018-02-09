//
//  SyncStrategy.swift
//  schulcloud
//
//  Created by Max Bothe on 08.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Result

protocol SyncStrategy {

    var resourceKeyAttribute: String { get }

    func queryItems<Query>(forQuery query: Query) -> [URLQueryItem] where Query: ResourceQuery 
    func validateResourceData(_ data: Data) -> Result<Void, SyncError>

    // key modification when accessing included data
    func includedDataKey(forAttribute attributeName: String)

    // how to extract data, included (meta)
    // - can throw (marshall)
    // - no default implementation?
    // - for both
    func extractResourceData() throws -> ResourceData
    func extractResourceData() throws -> [ResourceData]
    func extractAddtionalSyncData() throws -> AddtionalSyncData?

}
