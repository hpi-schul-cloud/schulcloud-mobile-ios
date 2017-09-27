//
//  BrightFutures+.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 14.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures

extension Future {
    func flatMap<U>(object: U) -> Future<U, Future.Value.Error> {
        return self.flatMap({ _ -> Future<U, Future.Value.Error> in
            return Future<U, Future.Value.Error>(value: object)
        })
    }
    
    func onErrorLogAndRecover(with object: Value.Value) -> Future<Value.Value, Future.Value.Error> {
        return self.recoverWith { (error) -> Future<Value.Value, Future.Value.Error> in
            log.error(error)
            return Future(value: object)
        }
    }
}
