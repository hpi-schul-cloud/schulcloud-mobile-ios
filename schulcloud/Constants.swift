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
        case web = "https://schul-cloud.org/"
        
        var url: URL {
            return URL(string: self.rawValue)!
        }
    }
    
    static let backend = Servers.production
    
    static let textStyleHtml = "<style>body{font-family: 'PT Sans', '-apple-system'; font-size: 17px;}a {color: #b10438; text-decoration: none}</style>"
}
