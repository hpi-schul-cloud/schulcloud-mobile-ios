//
//  SCError.swift
//  schulcloud
//
//  Created by Carl Gödecken on 15.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Marshal

public enum SCError: Error {
    case apiError(Int, String)
    case network(Error?)
    case unknown
    case firebase(Error)
    case jsonDeserialization(String)
    case database(String)
    case loginFailed(String)
    case wrongCredentials
    case other(String)
    
    init(value: SCError) {
        self = value
    }
    
    init(otherError error: Error) {
        if let marshalError = error as? MarshalError {
            self = .jsonDeserialization(marshalError.description)
        } else {
            self = .unknown // TODO
        }
    }
    
    init(apiResponse: Data?) {
        if let data = apiResponse,
            let deserialized = try? JSONSerialization.jsonObject(with: data, options: []),
            let object = deserialized as? [String: Any]
        {
            self.init(json: object)
        } else {
            self.init(value: .unknown)
        }
    }
    
    init(json: [String: Any]) {
        if let errorCode: Int = try? json.value(for: "code"),
            let errorMessage: String = try? json.value(for: "message"){
            self = .apiError(errorCode, errorMessage)
        } else {
            self = .unknown
        }
    }
}

extension SCError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .apiError(let code, let message):
            return "API error \(code): \(message)"
        case .loginFailed(let message):
            return "Error: \(message)"
        case .wrongCredentials:
            return "Error: Wrong credentials"
        case .unknown:
            return "Unknown error"
        case .jsonDeserialization(let reason):
            return "Failure to parse JSON: \(reason)"
        default:
            return self.localizedDescription
        }
    }
}

extension Error {
    var description: String {
        return (self as CustomStringConvertible).description
    }
}
