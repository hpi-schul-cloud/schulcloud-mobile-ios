//
//  CoreDataObserver.swift
//  schulcloud
//
//  Created by Max Bothe on 20.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import CoreData

class CoreDataObserver {

    static let shared = CoreDataObserver()

    func startObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: CoreDataHelper.persistentContainer.viewContext)
    }

    func stopObserving() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: CoreDataHelper.persistentContainer.viewContext)
    }

    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty {

        }

        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty {

        }

        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletes.isEmpty {

        }
    }

}
