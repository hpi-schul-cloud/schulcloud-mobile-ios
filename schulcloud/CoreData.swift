//
//  Sync.swift
//  schulcloud
//
//  Created by Carl Gödecken on 17.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData
import Marshal

// MARK: - Core Data stack


var managedObjectContext: NSManagedObjectContext = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
     */
    let persistentContainer = NSPersistentContainer(name: "schulcloud")
    persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
        if let error = error as NSError? {
            // Replace this implementation with code to handle the error appropriately.
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
    
    return persistentContainer.viewContext
}()

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

struct CoreDataHelper {
    public static func delete<T>(fetchRequest: NSFetchRequest<T>) throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        try managedObjectContext.execute(deleteRequest)
    }
}

@objc protocol IdObject {
    var id: String { get set }
}

extension IdObject where Self: NSManagedObject {
    
    static func findOrCreateWithId(data: MarshaledObject) throws -> Self {
        let id: String = try data.value(for: "_id")
        if let object = try self.find(by: id) {
            return object
        } else {
            let object = self.init(context: context)
            object.id = id
            return object
        }
    }
    
    static func find(by id: String) throws -> Self? {
        let fetchRequest = self.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        let result = try context.fetch(fetchRequest)
        if result.count > 1 {
            log.error("Found more than one result for \(fetchRequest): \(result)")
//            throw SCError.database("Found more than one result for \(fetchRequest)")
        }
        return result.first as? Self
    }
}
