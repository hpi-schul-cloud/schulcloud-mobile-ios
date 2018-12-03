//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import os

public struct Logger {
    private let log: OSLog

    public init(subsystem: String, category: String) {
        log = OSLog(subsystem: subsystem, category: category)
    }

    public func info(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .info, args)
    }

    public func debug(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .debug, args)
    }

    public func default_log(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .default, args)
    }

    public func error(_ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: log, type: .error, args)
    }

    public func fault(_ message: StaticString, _ args: CVarArg...) {
         os_log(message, log: log, type: .fault, args)
    }
}
