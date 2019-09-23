//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public struct BrandServers: Decodable {

    private enum CodingKeys: CodingKey {
        case dataPrivacy
        case imprint
        case web
        case backend
    }

    public let web: URL
    public let backend: URL
    public let imprint: URL
    public let dataPrivacy: URL

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        web = try container.decodeURL(for: .web)
        backend = try container.decodeURL(for: .backend)
        imprint = try container.decodeURL(for: .imprint)
        dataPrivacy = try container.decodeURL(for: .dataPrivacy)
    }
}

private extension KeyedDecodingContainer {
    func decodeURL(for key: K) throws -> URL {
        let value = try self.decode(String.self, forKey: key)
        return URL(string: value)!
    }
}
