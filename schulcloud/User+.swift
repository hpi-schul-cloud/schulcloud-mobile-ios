//
//  User+CoreDataClass.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 30.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData
import Marshal

extension User {
    
    static func upsert(data: MarshaledObject) throws -> User {
        let user = try self.findOrCreateWithId(data: data)
        user.email = try? data.value(for: "email")
        user.schoolId = try data.value(for: "schoolId")
        user.firstName = try data.value(for: "firstName")
        user.lastName = try data.value(for: "lastName")
        
        return user
    }
    
    typealias UserFuture = Future<User, SCError>
    static func fetch(by id: String) -> UserFuture {
        if let _user = try? User.find(by: id),
            let user = _user {
            return UserFuture(value: user)
        }
        return ApiHelper.request("users/\(id)").jsonObjectFuture()
            .flatMap { data -> UserFuture in
                do {
                    let user = try User.upsert(data: data)
                    return Future(value: user)
                }
                catch let error {
                    return UserFuture(error: .database(error.localizedDescription))
                }
        }
    }
}

extension User: IdObject {}
