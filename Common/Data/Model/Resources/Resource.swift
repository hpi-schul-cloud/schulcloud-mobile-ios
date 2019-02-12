//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public struct Resource: Codable {
    public var id: String
    public var originId: String
    public var providerName: String
    public var url: URL
    public var title: String
    public var description: String
    public var thumbnail: URL
    public var contentCategory: String
    public var mimeType: String
    public var userId: String
    public var updatedAt: String
    public var createdAt: String
    public var licenses: [String]
    public var tags: [String]
    public var version: Int
    public var clickCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case originId
        case providerName
        case url
        case title
        case description
        case thumbnail
        case contentCategory
        case mimeType
        case userId
        case updatedAt
        case createdAt
        case licenses
        case tags
        case version = "__v"
        case clickCount
    }
}
