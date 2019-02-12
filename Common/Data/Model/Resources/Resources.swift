//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public struct Resources: Codable {
    public var total: Int
    public var limit: Int
    public var skip: Int
    public var data: [Resource]
}
