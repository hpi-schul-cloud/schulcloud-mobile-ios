//
//  SynchronizationError.swift
//  schulcloud
//
//  Created by Max Bothe on 30.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Marshal

enum SyncError: Error {
    case api(APIError)
    case coreData(Error)
    case network(Error)
    case synchronization(SynchronizationError)
    case unknown(Error)

    case invalidURL(String?)
    case invalidResourceURL
    case invalidURLComponents(URL)

    //    case coreData(Error)
    //    case coreDataObjectNotFound
    //    case coreDataMoreThanOneObjectFound
    //    case coreDataTypeMismatch(expected: Any, found: Any)
}

enum APIError : Error {
    case invalidResponse
    case noData
    case response(statusCode: Int, headers: [AnyHashable: Any])
    case unknownServerError
    case serverError(message: String)
//    case resourceNotFound
    case serialization(SerializationError)
}

enum SerializationError : Error {
    case invalidDocumentStructure
    case topLevelEntryMissing
    case topLevelDataAndErrorsCoexist
    case jsonSerialization(Error)
    case resourceTypeMismatch(expected: String, found: String)
    case modelDeserialization(Error, onType: String)
    case includedModelDeserialization(Error, onType: String, forIncludedType: String, forKey: String)
}

enum SynchronizationError : Error {
    case noRelationshipBetweenEnities(from: Any, to: Any)
    case toManyRelationshipBetweenEnities(from: Any, to: Any)
    case abstractRelationshipNotUpdated(from: Any, to: Any, withKey: KeyType)
    case missingIncludedResource(from: Any, to: Any, withKey: KeyType)
    case missingEnityNameForResource(Any)
    case noMatchAbstractType(resourceType: Any, abstractType: Any)
}

enum NestedMarshalError: Error {
    case nestedMarshalError(Error, includeType: String, includeKey: KeyType)
}
