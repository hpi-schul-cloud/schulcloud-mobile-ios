//
//  Sync.swift
//  schulcloud
//
//  Created by Carl Gödecken on 17.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import BrightFutures
import CoreData
import Result

struct CoreDataHelper {

    static var persistentContainer = createPersistentContainer()

    static var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private static func createPersistentContainer() -> NSPersistentContainer {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let persistentContainer = NSPersistentContainer(name: "schulcloud")
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // TODO: Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            let managedObjectContext = persistentContainer.viewContext
            managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        })

        return persistentContainer
    }

    static func dropDatabase() {
        log.debug("Dropping database - recreating persistent container")
        CoreDataObserver.shared.stopObserving()

        let coordinator = persistentContainer.persistentStoreCoordinator
        let stores = coordinator.persistentStores

        do {
            try stores.forEach {
                try coordinator.remove($0)
                if let url = $0.url {
                    try FileManager.default.removeItem(at: url)
                }
            }
        } catch let error {
            // TODO: fail more gracefully
            fatalError(error.description)
        }

        persistentContainer = createPersistentContainer()
        CoreDataObserver.shared.startObserving()
    }

    public static func delete<T>(fetchRequest: NSFetchRequest<T>, context: NSManagedObjectContext) throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        try context.execute(deleteRequest)
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

//@objc protocol IdObject {
//    var id: String { get set }
//    static var entityName: String { get }
//}

//extension IdObject where Self: NSManagedObject {
//    
//    static func findOrCreateWithId(data: MarshaledObject, context: NSManagedObjectContext) throws -> Self {
//        let id: String = try data.value(for: "_id")
//        if let object = try self.find(by: id, context: context) {
//            return object
//        } else {
//            let object = self.init(context: context)
//            object.id = id
//            return object
//        }
//    }
//    
//    static func find(by id: String, context: NSManagedObjectContext) throws -> Self? {
//        let fetchRequest = NSFetchRequest(entityName: self.entityName) as NSFetchRequest<Self>
//        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
//        let result = try context.fetch(fetchRequest)
//        if result.count > 1 {
//            log.error("Found more than one result for \(fetchRequest): \(result)")
////            throw SCError.database("Found more than one result for \(fetchRequest)")
//        }
//        return result.first
//    }
//}

