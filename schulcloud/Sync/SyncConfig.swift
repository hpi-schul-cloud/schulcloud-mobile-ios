//
//  SyncConfig.swift
//  schulcloud
//
//  Created by Max Bothe on 08.02.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import CoreData

protocol SyncConfig {
    // Requests
    var baseURL: URL { get }
    var requestHeaders: [String: String] { get }

    // Core Data
    var persistentContainer: NSPersistentContainer { get }

    // (De-)Serialization strategy
    var syncStrategy: SyncStrategy { get }

    // delegates
    // TODO: make these static variables (blocks) which can be called
    func log(_ message: String, withLevel level: SyncLogLevel)
    func networkActivity(withType type: SyncNetworkActivityType)
}

extension SyncConfig {
    func log(_ message: String, withLevel level: SyncLogLevel) {}
    func networkActivity(withType type: SyncNetworkActivityType) {}
}

enum SyncLogLevel {
    case verbose
    case debug
    case info
    case warning
    case error
    case severe
}

enum SyncNetworkActivityType {
    case start
    case stop
}
