//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import Marshal
import SyncEngine

public final class Submission: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var comment: String?
    @NSManaged public var grade: Int32
    @NSManaged public var gradeComment: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var objectStateValue: Int16
    @NSManaged public var studentId: String

    @NSManaged public var files: Set<File>
    @NSManaged public var homework: Homework
    
    @nonobjc public static func fetchRequest() -> NSFetchRequest<Submission> {
        return NSFetchRequest<Submission>(entityName: "Submission")
    }
}

extension Submission: Pullable {
    public static var type: String {
        return "submissions"
    }

    public func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.comment = try? object.value(for: "comment")
        self.grade = (try? object.value(for: "grade")) ?? 0
        self.gradeComment = try? object.value(for: "gradeComment")
        self.createdAt = try object.value(for: "createdAt")
        self.updatedAt = try object.value(for: "updatedAt")

        let files = (try object.value(for: "fileIds") as [[String: Any]]) as [MarshaledObject]

        guard let context = self.managedObjectContext else { throw SCError.unknown }
        try context.performAndWait {
            guard let userDirectory = File.by(id: FileHelper.userDirectoryID, in: context) else {
                throw SCError.unknown
            }
            for file in files {
                if let toUpdate = try self.files.first { $0.id == (try file.value(for: "_id")) } {
                    try File.update(file: toUpdate, with: file)
                } else {
                    let newFile = try File.createOrUpdate(inContext: context, parentFolder: userDirectory, data: file)
                    self.files.insert(newFile)
                }
            }
        }

        let homeworkId: String = try object.value(for: "homeworkId")
        try context.performAndWait {
            let fetchRequest = Homework.fetchRequest() as NSFetchRequest<Homework>
            fetchRequest.predicate = NSPredicate(format: "id == %@", homeworkId)
            let result = context.fetchSingle(fetchRequest)
            switch result {
            case .failure(let error):
                throw error
            case .success(let homework):
                self.homework = homework
            }
        }

        context.saveWithResult()
    }
}

extension Submission: Pushable {
    public func resourceRelationships() -> [String : AnyObject]? {
        return nil
    }

    public var objectState: ObjectState {
        get {
            return ObjectState(rawValue: self.objectStateValue)!
        }
        set {
            self.objectStateValue = newValue.rawValue
        }
    }

    public func markAsUnchanged() {
        self.objectState = .unchanged
    }

    public func resourceAttributes() -> [String : Any] {
        return [
            "comment": self.comment,
            "grade": self.grade,
            "gradeComment": self.gradeComment,
            "createdAt": Homework.dateFormatter.string(from: self.createdAt),
            "updatedAt": Homework.dateFormatter.string(from: self.updatedAt),
            "fileIds": self.files.map { $0.id }
        ]
    }
}
