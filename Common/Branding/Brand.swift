//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import UIKit

public struct Brand: Decodable {

    private enum CodingKeys: CodingKey {
        case name
        case imprintURL
        case dataPrivacyURL

        case servers
        case colors
        case testAccounts
    }

    public static let `default`: Brand = {
        let data = NSDataAsset(name: "BrandConfiguration")?.data
        let decoder = PropertyListDecoder()
        return try! decoder.decode(Brand.self, from: data!) // swiftlint:disable:this force_try
    }()

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        imprintURL = try container.decodeURL(for: .imprintURL)
        dataPrivacyURL = try container.decodeURL(for: .dataPrivacyURL)

        servers = try container.decode(BrandServers.self, forKey: .servers)
        colors = try container.decode(BrandColors.self, forKey: .colors)
        testAccounts = try container.decode(TestAccounts.self, forKey: .testAccounts)
    }

    public let name: String
    public let imprintURL: URL
    public let dataPrivacyURL: URL

    public let servers: BrandServers
    public let colors: BrandColors
    public let testAccounts: TestAccounts

}

extension KeyedDecodingContainer {
    func decodeURL(for key: K) throws -> URL {
        let value = try self.decode(String.self, forKey: key)
        return URL(string: value)!
    }
}
