//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public struct TestAccounts: Decodable {
    public let student: TestAccount
    public let teacher: TestAccount
}

public struct TestAccount: Decodable {
    public let username: String
    public let password: String
}
