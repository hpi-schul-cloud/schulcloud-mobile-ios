//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import UIKit

public struct Brand: Decodable {

    public static let `default`: Brand = {
        let data = NSDataAsset(name: "BrandConfiguration")?.data
        let decoder = PropertyListDecoder()
        return try! decoder.decode(Brand.self, from: data!) // swiftlint:disable:this force_try
    }()

    public let servers: BrandServers
    public let colors: BrandColors
    public let testAccounts: TestAccounts

}
