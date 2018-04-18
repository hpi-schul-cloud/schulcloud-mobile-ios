//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import Result

struct CoreDataHelper {

    static var persistentContainer: NSPersistentContainer = {

        guard let securedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.schulcloud") else {
            fatalError("Can't access shared container")
        }

        let storeDescription = NSPersistentStoreDescription(url: securedContainerURL.appendingPathComponent("schulcloud.sqlite"))
        let container = NSPersistentContainer(name: "schulcloud")
        container.persistentStoreDescriptions.append(storeDescription)
        container.loadPersistentStores { _, error in
            if let error = error {
                log.error("Unresolved error \(error)")
                fatalError("Unresolved error \(error)")
            }

            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        }

        return container
    }()

    static var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    static func clearCoreDataStorage() -> Future<Void, SCError> {
        return self.persistentContainer.managedObjectModel.entitiesByName.keys.traverse { entityName in
            return self.clearCoreDataEntity(entityName)
        }.asVoid()
    }

    private static func clearCoreDataEntity(_ entityName: String) -> Future<Void, SCError> {
        let promise = Promise<Void, SCError>()

        self.persistentContainer.performBackgroundTask { privateManagedObjectContext in
            privateManagedObjectContext.shouldDeleteInaccessibleFaults = true
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try privateManagedObjectContext.execute(deleteRequest) as? NSBatchDeleteResult
                guard let objectIDArray = result?.result as? [NSManagedObjectID] else { return }
                let changes = [NSDeletedObjectsKey: objectIDArray]
                log.verbose("Try to delete all enities of \(entityName) (\(objectIDArray.count) enities)")
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
                try privateManagedObjectContext.save()

                promise.success(())
            } catch {
                log.error("Failed to bulk delete all enities of \(entityName) - \(error)")
                promise.failure(.coreData(error))
            }
        }

        return promise.future
    }

}

extension NSManagedObjectContext {

    func fetchSingle<T>(_ fetchRequest: NSFetchRequest<T>) -> Result<T, SCError> where T: NSManagedObject {
        do {
            let objects = try self.fetch(fetchRequest)

            guard objects.count < 2 else {
                return .failure(.coreDataObjectNotFound)
            }

            guard let object = objects.first else {
                return .failure(.coreDataMoreThanOneObjectFound)
            }

            return .success(object)
        } catch {
            return .failure(.coreData(error))
        }
    }

    func fetchMultiple<T>(_ fetchRequest: NSFetchRequest<T>) -> Result<[T], SCError> where T: NSManagedObject {
        do {
            let objects = try self.fetch(fetchRequest)
            return .success(objects)
        } catch {
            return .failure(.coreData(error))
        }
    }

    func typedObject<T>(with id: NSManagedObjectID) -> T where T: NSManagedObject {
        let managedObject = self.object(with: id)
        guard let object = managedObject as? T else {
            let message = "Type mismatch for NSManagedObject (required)"
            let reason = "required: \(T.self), found: \(type(of: managedObject))"
            log.error("\(message): \(reason)")
            fatalError("\(message): \(reason)")
        }

        return object
    }

    func existingTypedObject<T>(with id: NSManagedObjectID) -> T? where T: NSManagedObject {
        guard let managedObject = try? self.existingObject(with: id) else {
            log.info("NSManagedObject could not be retrieved by id (\(id))")
            return nil
        }

        guard let object = managedObject as? T else {
            let message = "Type mismatch for NSManagedObject"
            let reason = "expected: \(T.self), found: \(type(of: managedObject))"
            log.error("\(message): \(reason)")
            return nil
        }

        return object
    }

    func saveWithResult() -> Result<Void, SCError> {
        do {
            if self.hasChanges {
                try self.save()
            }

            return .success(())
        } catch {
            return .failure(.coreData(error))
        }
    }

}

// See https://oleb.net/blog/2018/02/performandwait/
extension NSManagedObjectContext {
    func performAndWait<T>(_ block: () throws -> T) rethrows -> T {
        return try _performAndWaitHelper( task: performAndWait, execute: block) { throw $0 }
    }

    /// Helper function for convincing the type checker that
    /// the rethrows invariant holds for performAndWait.
    ///
    /// Source: https://github.com/apple/swift/blob/bb157a070ec6534e4b534456d208b03adc07704b/stdlib/public/SDK/Dispatch/Queue.swift#L228-L249
    private func _performAndWaitHelper<T>(
        task: (() -> Void) -> Void,
        execute work: () throws -> T,
        rescue: ((Error) throws -> (T))) rethrows -> T {
        var result: T?
        var error: Error?
        withoutActuallyEscaping(work) { internalWork in
            task {
                do {
                    result = try internalWork()
                } catch let e {
                    error = e
                }
            }
        }

        if let e = error {
            return try rescue(e)
        } else {
            return result!
        }
    }
}
