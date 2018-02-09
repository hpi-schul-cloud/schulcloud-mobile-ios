//
//  Pushable.swift
//  schulcloud
//
//  Created by Max Bothe on 30.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData
import Result

enum ObjectState: Int16 {
    case unchanged = 0
    case new
    case modified
    case deleted
}

protocol IncludedPushable {
    func resourceAttributes() -> [String: Any]
}

protocol Pushable : ResourceTypeRepresentable, IncludedPushable, NSFetchRequestResult {
    var objectState: ObjectState { get }
    var deleteAfterSync: Bool { get }

    func resourceData() -> Result<Data, SyncError>
    func resourceRelationships() -> [String: AnyObject]?
    func markAsUnchanged()
}

extension Pushable {

    var deleteAfterSync: Bool {
        return false
    }

    func resourceData() -> Result<Data, SyncError> {
        do {
            var data: [String: Any] = [ "type": Self.type ]
            if let newResource = self as? ResourceRepresentable, self.objectState != .new {
                data["id"] = newResource.id
            }

            data["attributes"] = self.resourceAttributes()
            if let resourceRelationships = self.resourceRelationships() {
                var relationships: [String: Any] = [:]
                for (relationshipName, object) in resourceRelationships {
                    if let resource = object as? ResourceRepresentable {
                        relationships[relationshipName] = ["data": resource.identifier]
                    } else if let resources = object as? [ResourceRepresentable] {
                        relationships[relationshipName] = ["data": resources.map { $0.identifier }]
                    }
                }
                if !relationships.isEmpty {
                    data["relationships"] = relationships
                }
            }

            let json = ["data": data]
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            return .success(jsonData)
        } catch {
            return .failure(.api(.serialization(.jsonSerialization(error))))
        }
    }

    func resourceRelationships() -> [String: AnyObject]? {
        return nil
    }

}
