//
//  Bundle+.swift
//  Common
//
//  Created by Florian Morel on 24.09.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation

public extension Bundle {
    public var appGroupIdentifier: String? {
        return self.infoDictionary?["APP_GROUP_IDENTIFIER"] as? String
    }
}
