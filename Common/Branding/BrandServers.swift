//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public struct BrandServers: Decodable {

    private enum CodingKeys: CodingKey {
        case web
        case backend
    }

    public let web: URL
    public let backend: URL

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        web = try container.decodeURL(for: .web)
        backend = try container.decodeURL(for: .backend)
    }
}
