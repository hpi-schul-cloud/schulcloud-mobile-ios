//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import Marshal
import SyncEngine

public enum SCError: Error {
    case apiError(Int, String)
    case network(Error?)
    case unknown
    case firebase(Error)
    case jsonDeserialization(String)
    case jsonSerialization(String)
    case loginFailed(String)
    case wrongCredentials
    case other(String)

    case coreData(Error)
    case coreDataObjectNotFound
    case coreDataMoreThanOneObjectFound

    case synchronization(SyncError)

    init(value: SCError) {
        self = value
    }

    init(otherError error: Error) {
        if let marshalError = error as? MarshalError {
            self = .jsonDeserialization(String(reflecting: marshalError))
        } else {
            self = .unknown
        }
    }

    init(apiResponse: Data?) {
        if let data = apiResponse,
           let deserialized = try? JSONSerialization.jsonObject(with: data, options: []),
           let object = deserialized as? [String: Any] {
            self.init(json: object)
        } else {
            self.init(value: .unknown)
        }
    }

    init(json: [String: Any]) {
        if let errorCode: Int = try? json.value(for: "code"), let errorMessage: String = try? json.value(for: "message") {
            self = .apiError(errorCode, errorMessage)
        } else {
            self = .unknown
        }
    }
}

extension SCError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .apiError(code, message):
            return "API error \(code): \(message)"
        case .loginFailed(let message):
            return "Error: \(message)"
        case .wrongCredentials:
            return "Error: Wrong credentials"
        case .jsonDeserialization(let reason):
            return "Failure to parse JSON: \(reason)"
        default:
            return self.localizedDescription
        }
    }
}

extension SCError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .network(let error):
            return "Network error: \(String(reflecting: error))"
        case .synchronization(let error):
            return "Synchronization failure: \(String(reflecting: error))"
        case let .apiError(code, message):
            return "Backend API error \(code): \(message)"

        case .loginFailed(let message):
            return "Login failed: \(message)"
        case .wrongCredentials:
            return "Wrong credentials used for login"

        case .jsonDeserialization(let reason):
            return "JSON Deserialization: \(reason)"
        case .jsonSerialization(let reason):
            return "JSON Serialization: \(reason)"

        case .coreData(let error):
            return "Core Data error: \(String(reflecting: error))"
        case .coreDataObjectNotFound:
            return "CoreData object not found"
        case .coreDataMoreThanOneObjectFound:
            return "CoreData more that one object found"

        case .firebase(let error):
            return "Firebase failure: \(String(reflecting: error))"

        case .other(let message):
            return "Another failure occured: \(message)"

        case .unknown:
            return "Unknown error"
        }
    }
}

extension Error {
    public var description: String {
        return (self as CustomStringConvertible).description
    }
}
