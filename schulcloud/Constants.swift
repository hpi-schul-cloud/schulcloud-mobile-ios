//
//  Constants.swift
//  schulcloud
//
//  Created by Carl Gödecken on 05.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation

class Constants {
    enum Servers: String {
        case staging = "https://schul.tech:3030/"
        case production = "https://schul-cloud.org:8080/"
        
        var url: URL {
            return URL(string: self.rawValue)!
        }
    }
    
    static let backend = Servers.staging
}
