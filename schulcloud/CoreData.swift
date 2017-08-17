//
//  Sync.swift
//  schulcloud
//
//  Created by Carl Gödecken on 17.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData
import Marshal

// MARK: - Core Data stack

var persistentContainer = createPersistentContainer()

var managedObjectContext: NSManagedObjectContext {
    return persistentContainer.viewContext
}

fileprivate func createPersistentContainer() -> NSPersistentContainer {
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
    })
    
    return persistentContainer
}

func recreatePersistentContainer() {
    log.debug("Dropping database - recreating persistent container")
    CoreDataObserver.shared.removeObserver(on: managedObjectContext)
    
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
    CoreDataObserver.shared.observeChanges(on: managedObjectContext)
}

// MARK: - Core Data Saving support

func saveContext () {
    if managedObjectContext.hasChanges {
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

func save(privateContext privateMoc: NSManagedObjectContext) -> Future<Void, SCError> {
    let promise = Promise<Void, SCError>()
    privateMoc.perform {
        do {
            try privateMoc.save()
            managedObjectContext.performAndWait {
                do {
                    try managedObjectContext.save()
                    promise.success(Void())
                } catch {
                    log.error("Failure to save context: \(error)")
                    promise.failure(.database(error.description))
                }
            }
        } catch {
            log.error("Failure to save context: \(error)")
            promise.failure(.database(error.description))
        }
    }
    return promise.future
}

class CoreDataObserver {
    
    static let shared = CoreDataObserver()
    
    let notificationCenter = NotificationCenter.default
    
    // MARK: temp core data observer
    func observeChanges(on managedObjectContext: NSManagedObjectContext) {
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
    }
    
    func removeObserver(on managedObjectContext: NSManagedObjectContext) {
        notificationCenter.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
    }
    
    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
            print("--- INSERTS ---")
            print(inserts)
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
            print("--- UPDATES ---")
            var unchanged = 0
            for update in updates {
                let changed = update.changedValues()
                if changed.count > 0 {
                    print(changed)
                } else {
                    unchanged += 1
                }
            }
            print("\(unchanged) unchanged")
        }
        
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
            print("--- DELETES ---")
            print(deletes)
        }
    }
}

struct CoreDataHelper {
    public static func delete<T>(fetchRequest: NSFetchRequest<T>, context: NSManagedObjectContext = managedObjectContext) throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        try context.execute(deleteRequest)
    }
}

@objc protocol IdObject {
    var id: String { get set }
    static var entityName: String { get }
}

extension IdObject where Self: NSManagedObject {
    
    static func findOrCreateWithId(data: MarshaledObject, context: NSManagedObjectContext) throws -> Self {
        let id: String = try data.value(for: "_id")
        if let object = try self.find(by: id, context: context) {
            return object
        } else {
            let object = self.init(context: context)
            object.id = id
            return object
        }
    }
    
    static func find(by id: String, context: NSManagedObjectContext) throws -> Self? {
        let fetchRequest = NSFetchRequest(entityName: self.entityName) as NSFetchRequest<Self>
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        let result = try context.fetch(fetchRequest)
        if result.count > 1 {
            log.error("Found more than one result for \(fetchRequest): \(result)")
//            throw SCError.database("Found more than one result for \(fetchRequest)")
        }
        return result.first
    }
}
