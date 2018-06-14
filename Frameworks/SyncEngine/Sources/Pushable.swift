//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import Result

public enum ObjectState: Int16 {
    case unchanged = 0
    case new
    case modified
    case deleted
}

public protocol IncludedPushable {
    func resourceAttributes() -> [String: Any]
}

public protocol Pushable: ResourceTypeRepresentable, IncludedPushable, NSFetchRequestResult {
    var objectState: ObjectState { get }

    func resourceRelationships() -> [String: AnyObject]?
    func markAsUnchanged()
}

extension Pushable {

    func resourceRelationships() -> [String: AnyObject]? {
        return nil
    }

}
