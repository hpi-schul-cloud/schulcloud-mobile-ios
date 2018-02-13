//
//  Pullable.swift
//  schulcloud
//
//  Created by Max Bothe on 30.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData
import Marshal


protocol Pullable : ResourceRepresentable {

    static func value(from object: ResourceData, with context: SynchronizationContext) throws -> Self

    mutating func update(from object: ResourceData, with context: SynchronizationContext) throws

}

extension Pullable where Self: NSManagedObject {

    static func value(from object: ResourceData, with context: SynchronizationContext) throws -> Self {
        try context.strategy.validateObjectCreation(object: object, toHaveType: Self.type)
        var managedObject = self.init(entity: self.entity(), insertInto: context.coreDataContext)
        try managedObject.id = object.value(for: context.strategy.resourceKeyAttribute)
        try managedObject.update(from: object, with: context)
        return managedObject
    }

//    fileprivate func findIncludedObject(for objectIdentifier: ResourceIdentifier, in includes: [ResourceData]?) -> ResourceData? {
//        guard let includedData = includes else {
//            return nil
//        }
//
//        return includedData.first { item in
//            guard let identifier = try? ResourceIdentifier(object: item) else {
//                return false
//            }
//            return objectIdentifier.id == identifier.id && objectIdentifier.type == identifier.type
//        }
//    }


    func updateRelationship<A>(forKeyPath keyPath: ReferenceWritableKeyPath<Self, A>,
                               forKey key: KeyType,
                               fromObject object: ResourceData,
                               with context: SynchronizationContext) throws where A: NSManagedObject & Pullable {
        switch context.strategy.findIncludedObject(forKey: key, ofObject: object, with: context) {
        case let .object(_, includedObject):
            var existingObject = self[keyPath: keyPath] // TODO: also check if id is equal. update() does not updates the id
            do {
                try existingObject.update(from: includedObject, with: context)
            } catch let error as MarshalError {
                throw NestedMarshalError.nestedMarshalError(error, includeType: A.type, includeKey: key)
            }
        default:
            throw SynchronizationError.missingIncludedResource(from: Self.self, to: A.self, withKey: key)
        }

//        let resourceIdentifier = try object.value(for: "\(key).data") as ResourceIdentifier
//
//        if let includedObject = self.findIncludedObject(for: resourceIdentifier, in: includes) {
//            var existingObject = self[keyPath: keyPath] // TODO: also check if id is equal. update() does not updates the id
//            do {
//                try existingObject.update(withObject: includedObject, withAdditionalSyncData: additionalSyncData, inContext: context)
//            } catch let error as MarshalError {
//                throw NestedMarshalError.nestedMarshalError(error, includeType: A.type, includeKey: key)
//            }
//        } else {
//            throw SynchronizationError.missingIncludedResource(from: Self.self, to: A.self, withKey: key)
//        }
    }

    func updateRelationship<A>(forKeyPath keyPath: ReferenceWritableKeyPath<Self, A?>,
                               forKey key: KeyType,
                               fromObject object: ResourceData,
                               with context: SynchronizationContext) throws where A: NSManagedObject & Pullable {
        switch context.strategy.findIncludedObject(forKey: key, ofObject: object, with: context) {
        case let .object(resourceId, includedObject):
            do {
                if var existingObject = self[keyPath: keyPath] { // TODO: also check if id is equal. update() does not updates the id
                    try existingObject.update(from: includedObject, with: context)
                } else {
                    if var fetchedResource = try SyncEngine.findExistingResource(withId: resourceId, ofType: A.self, inContext: context.coreDataContext) {
                        try fetchedResource.update(from: includedObject, with: context)
                        self[keyPath: keyPath] = fetchedResource
                    } else {
                        self[keyPath: keyPath] = try A.value(from: includedObject, with: context)
                    }
                }
            } catch let error as MarshalError {
                throw NestedMarshalError.nestedMarshalError(error, includeType: A.type, includeKey: key)
            }
        case let .id(resourceId):
            if let fetchedResource = try SyncEngine.findExistingResource(withId: resourceId, ofType: A.self, inContext: context.coreDataContext) {
                self[keyPath: keyPath] = fetchedResource
            } else {
                log.info("relationship update saved (\(Self.type) --> \(A.type)?)")
            }
        case .notExisting:
            // relationship does not exist, so we reset delete the possible relationship
            self[keyPath: keyPath] = nil
        }

//
//        guard let resourceIdentifier = try? object.value(for: "\(key).data") as ResourceIdentifier else {
//            // relationship does not exist, so we reset delete the possible relationship
//            self[keyPath: keyPath] = nil
//            return
//        }
//
//        if let includedObject = self.findIncludedObject(for: resourceIdentifier, in: includes) {
//            do {
//                if var existingObject = self[keyPath: keyPath] { // TODO: also check if id is equal. update() does not updates the id
//                    try existingObject.update(withObject: includedObject, withAdditionalSyncData: additionalSyncData, inContext: context)
//                } else {
//                    if var fetchedResource = try SyncEngine.findExistingResource(withId: resourceIdentifier.id, ofType: A.self, inContext: context) {
//                        try fetchedResource.update(withObject: includedObject, withAdditionalSyncData: additionalSyncData, inContext: context)
//                        self[keyPath: keyPath] = fetchedResource
//                    } else {
//                        self[keyPath: keyPath] = try A.value(from: includedObject, withAdditionalSyncData: additionalSyncData, inContext: context)
//                    }
//                }
//            } catch let error as MarshalError {
//                throw NestedMarshalError.nestedMarshalError(error, includeType: A.type, includeKey: key)
//            }
//        } else {
//            if let fetchedResource = try SyncEngine.findExistingResource(withId: resourceIdentifier.id, ofType: A.self, inContext: context) {
//                self[keyPath: keyPath] = fetchedResource
//            } else {
//                log.info("relationship update saved (\(Self.type) --> \(A.type)?)")
//            }
//        }
    }

    func updateRelationship<A>(forKeyPath keyPath: ReferenceWritableKeyPath<Self, Set<A>>,
                               forKey key: KeyType,
                               fromObject object: ResourceData,
                               with context: SynchronizationContext) throws where A: NSManagedObject & Pullable {
        var currentObjects = Set(self[keyPath: keyPath])



        //        let resourceIdentifiers = try object.value(for: "\(key).data") as [ResourceIdentifier]

        do {
            switch context.strategy.findIncludedObjects(forKey: key, ofObject: object, with: context) {
            case let .included(resourceIdsAndObjects, resourceIds):
                for (resourceId, includedObject) in resourceIdsAndObjects {
                    if var currentObject = currentObjects.first(where: { $0.id == resourceId }) {
                        try currentObject.update(from: includedObject, with: context)
                        if let index = currentObjects.index(where: { $0 == currentObject }) {
                            currentObjects.remove(at: index)
                        }
                    } else {
                        if var fetchedResource = try SyncEngine.findExistingResource(withId: resourceId, ofType: A.self, inContext: context.coreDataContext) {
                            try fetchedResource.update(from: includedObject, with: context)
                            self[keyPath: keyPath].insert(fetchedResource)
                        } else {
                            let newObject = try A.value(from: includedObject, with: context)
                            self[keyPath: keyPath].insert(newObject)
                        }
                    }
                }

                for resourceId in resourceIds {
                    if let currentObject = currentObjects.first(where: { $0.id == resourceId }) {
                        if let index = currentObjects.index(where: { $0 == currentObject }) {
                            currentObjects.remove(at: index)
                        }
                    } else {
                        if let fetchedResource = try SyncEngine.findExistingResource(withId: resourceId, ofType: A.self, inContext: context.coreDataContext) {
                            self[keyPath: keyPath].insert(fetchedResource)
                        }
                    }
                }
            case .notExisting:
                break
            }
//            for resourceIdentifier in resourceIdentifiers {
//                if var currentObject = currentObjects.first(where: { $0.id == resourceIdentifier.id }) {
//                    if let includedObject = self.findIncludedObject(for: resourceIdentifier, in: includes) {
//                        try currentObject.update(withObject: includedObject, withAdditionalSyncData: additionalSyncData, inContext: context)
//                    }
//
//                    if let index = currentObjects.index(where: { $0 == currentObject }) {
//                        currentObjects.remove(at: index)
//                    }
//                } else {
//                    if let includedObject = self.findIncludedObject(for: resourceIdentifier, in: includes) {
//                        if var fetchedResource = try SyncEngine.findExistingResource(withId: resourceIdentifier.id, ofType: A.self, inContext: context) {
//                            try fetchedResource.update(withObject: includedObject, withAdditionalSyncData: additionalSyncData, inContext: context)
//                            self[keyPath: keyPath].insert(fetchedResource)
//                        } else {
//                            let newObject = try A.value(from: includedObject, withAdditionalSyncData: additionalSyncData, inContext: context)
//                            self[keyPath: keyPath].insert(newObject)
//                        }
//                    } else {
//                        if let fetchedResource = try SyncEngine.findExistingResource(withId: resourceIdentifier.id, ofType: A.self, inContext: context) {
//                            self[keyPath: keyPath].insert(fetchedResource)
//                        } else {
//                            log.info("relationship update saved (\(Self.type) --> Set<\(A.type)>)")
//                        }
//                    }
//                }
//            }
        } catch let error as MarshalError {
            throw NestedMarshalError.nestedMarshalError(error, includeType: A.type, includeKey: key)
        }

        // TODO: really?
        for currentObject in currentObjects {
            context.coreDataContext.delete(currentObject)
        }
    }

    func updateAbstractRelationship<A>(forKeyPath keyPath: ReferenceWritableKeyPath<Self, A?>,
                                       forKey key: KeyType,
                                       fromObject object: ResourceData,
                                       with context: SynchronizationContext,
                                       updatingBlock block: (AbstractPullableContainer<Self, A>) throws -> Void) throws {
        let container = AbstractPullableContainer<Self, A>(onResource: self,
                                                           withKeyPath: keyPath,
                                                           forKey: key,
                                                           fromObject: object,
                                                           with: context)
        try block(container)
    }

}

class AbstractPullableContainer<A, B> where A: NSManagedObject & Pullable, B: NSManagedObject & AbstractPullable {
    let resource: A
    let keyPath: ReferenceWritableKeyPath<A, B?>
    let key: KeyType
    let object: ResourceData
    let context: SynchronizationContext

    init(onResource resource: A,
         withKeyPath keyPath: ReferenceWritableKeyPath<A, B?>,
         forKey key: KeyType,
         fromObject object: ResourceData,
         with context: SynchronizationContext) {
        self.resource = resource
        self.keyPath = keyPath
        self.key = key
        self.object = object
        self.context = context
    }

    func update<C>(forType type : C.Type) throws where C : NSManagedObject & Pullable {
        let resourceIdentifier = try self.object.value(for: "\(self.key).data") as ResourceIdentifier

        guard resourceIdentifier.type == C.type else { return }

        switch self.context.strategy.findIncludedObject(forKey: self.key, ofObject: self.object, with: self.context) {
        case let .object(_, includedObject):
            do {
                if var existingObject = self.resource[keyPath: self.keyPath] as? C{
                    try existingObject.update(from: includedObject, with: context)
                } else if let newObject = try C.value(from: includedObject, with: context) as? B {
                    self.resource[keyPath: self.keyPath] = newObject
                }
            } catch let error as MarshalError {
                throw NestedMarshalError.nestedMarshalError(error, includeType: C.type, includeKey: key)
            }
        default:
            // TODO throw error
            break
        }


//        if let includedObject = self.resource.findIncludedObject(for: resourceIdentifier, in: self.includes) {
//            do {
//                if var existingObject = self.resource[keyPath: self.keyPath] as? C{
//                    try existingObject.update(withObject: includedObject, withAdditionalSyncData: self.additionalSyncData, inContext: context)
//                } else if let newObject = try C.value(from: includedObject, withAdditionalSyncData: self.additionalSyncData, inContext: context) as? B {
//                    self.resource[keyPath: self.keyPath] = newObject
//                }
//            } catch let error as MarshalError {
//                throw NestedMarshalError.nestedMarshalError(error, includeType: C.type, includeKey: key)
//            }
//        }
    }

}

protocol AbstractPullable {}
