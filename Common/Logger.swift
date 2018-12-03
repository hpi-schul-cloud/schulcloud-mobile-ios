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

    private func log(type: OSLogType, file: String, _ message: String, _ args: CVaListPointer) {
        let expendedMessage = NSString(format: message, arguments: args) as String
        if let url = URL(string: file) {
            os_log("[%@] %@", log: log, type: type, url.lastPathComponent, expendedMessage)
        } else {
            os_log("%@", log: log, type: type, expendedMessage)
        }

    }

    public func info(_ message: String, file: String = #file, _ arguments: CVarArg...) {
        withVaList(arguments) { args -> () in
            self.log(type: .info, file: file, message, args)
        }
    }

    public func debug(_ message: String, file: String = #file, _ arguments: CVarArg...) {
        withVaList(arguments) { args -> () in
            self.log(type: .debug, file: file, message, args)
        }
    }

    public func warning(_ message: String, file: String = #file, _ arguments: CVarArg...) {
        withVaList(arguments) { args -> () in
            self.log(type: .default, file: file, message, args)
        }
    }

    public func error(_ message: String, file: String = #file, _ arguments: CVarArg...) {
        withVaList(arguments) { args -> () in
            self.log(type: .error, file: file, message, args)
        }
    }

    public func fault(_ message: String, file: String = #file, _ arguments: CVarArg...) {
        withVaList(arguments) { args -> () in
            self.log(type: .fault, file: file, message, args)
        }
    }
}
