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
    func flatMapToObject<U>(_ object: U) -> Future<U, Future.Value.Error> {
        return self.flatMap({ _ -> Future<U, Future.Value.Error> in
            return Future<U, Future.Value.Error>(value: object)
        })
    }
}
