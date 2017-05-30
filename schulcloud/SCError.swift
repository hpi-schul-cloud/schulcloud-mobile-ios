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
            let object = deserialized as? [String: Any],
            let errorCode: Int = try? object.value(for: "code"),
            let errorMessage: String = try? object.value(for: "message")
        {
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
        default:
            return self.localizedDescription
        }
    }
}
