//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import SyncEngine

public final class Submission: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var comment: String?
    @NSManaged public var grade: Int32
    @NSManaged public var gradeComment: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

    @NSManaged public var files: Set<File>
}

extension Submission: Pullable {
    public static var type: String {
        return "submissions"
    }

    public func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.id = try object.value(for: "_id")
        self.comment = try? object.value(for: "comment")
        self.grade = (try? object.value(for: "grade")) ?? 0
        self.gradeComment = try? object.value(for: "gradeComment")
        self.createdAt = try? object.value(for: "createdAt")
        self.updatedAt = try? object.value(for: "updatedAt")

        let keyPath = \Submission.files

        try self.updateRelationship(forKeyPath: keyPath, forKey: "fileIds", fromObject: object, with: context)
    }
}
