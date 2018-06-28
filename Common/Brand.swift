//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import UIKit

public struct Brand: Decodable {

    private enum CodingKeys: CodingKey {
        case servers
        case colors
    }

    public static let `default`: Brand = {
        let data = NSDataAsset(name: "BrandConfiguration")?.data
        let decoder = PropertyListDecoder()
        return try! decoder.decode(Brand.self, from: data!) // swiftlint:disable:this force_try
    }()

    public let servers: BrandServers
    public let colors: BrandColors

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.colors = try container.decode(BrandColors.self, forKey: .colors)
        self.servers = try container.decode(BrandServers.self, forKey: .servers)
    }
}
