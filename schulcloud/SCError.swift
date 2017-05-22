//
//  SCError.swift
//  schulcloud
//
//  Created by Carl Gödecken on 15.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation

enum SCError: Error {
    case apiError([String: Any])
    case network(Error?)
    case unknown
    case firebase(Error)
    
    init(apiResponse: Data?) {
        if let data = apiResponse,
            let deserialized = try? JSONSerialization.jsonObject(with: data, options: []),
            let errorJson = deserialized as? [String: Any] {
            self = .apiError(errorJson)
        } else {
            self = .unknown
        }
    }
}
