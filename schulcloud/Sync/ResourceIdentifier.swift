//
//  ResourceIdentifier.swift
//  schulcloud
//
//  Created by Max Bothe on 30.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Marshal

struct ResourceIdentifier: Unmarshaling {

    let type: String
    let id: String

    init(object: ResourceData) throws {
        self.type = try object.value(for: "type")
        self.id = try object.value(for: "id")
    }

}
