//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

public struct BrandColors: Decodable {

    private enum CodingKeys: CodingKey {
        case primary
        case secondary
        case tertiary
    }

    public let primary: UIColor
    public let secondary: UIColor
    public let tertiary: UIColor

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.primary = try container.decodeColor(forKey: .primary)
        self.secondary = try container.decodeColor(forKey: .secondary)
        self.tertiary = try container.decodeColor(forKey: .tertiary)
    }
}

private extension KeyedDecodingContainer {

    func decodeColor(forKey key: K) throws -> UIColor {
        let value = try self.decode(String.self, forKey: key)
        return UIColor(hexString: value)!
    }
}

