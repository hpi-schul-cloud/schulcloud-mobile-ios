//
//  HomeworkSubmission+.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 27.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData
import Marshal

extension HomeworkSubmission {
    static func upsert(inContext context: NSManagedObjectContext, object: MarshaledObject, for homework: Homework) -> Future<HomeworkSubmission, SCError> {
        do {
            let submission = try HomeworkSubmission.findOrCreateWithId(data: object, context: context)
            
            submission.homework = homework
            submission.comment = try object.value(for: "comment")
            submission.grade = (try? object.value(for: "grade")) ?? 0
            submission.gradeComment = try? object.value(for: "gradeComment")
            
            let studentId: String? = try? object.value(for: "studentId")
            let studentFuture = submission.fetchUser(by: studentId, context: context).onErrorLogAndRecover(with: Void())
            
            return studentFuture.flatMap(object: homework).flatMap(object: submission)
        } catch let error as MarshalError {
            return Future(error: .jsonDeserialization(error.description))
        } catch let error {
            return Future(error: .database(error.localizedDescription))
        }
    }
    
    func fetchUser(by id: String?, context: NSManagedObjectContext) -> Future<Void, SCError> {
        guard let id = id else { return Future(value: Void())}
        return User.fetchQueue.sync {
            return User.fetch(by: id, inContext: context)
                .andOnSuccess { self.student = $0 }
                .asVoid()
        }
    }
}

extension HomeworkSubmission: IdObject {
    static let entityName = "HomeworkSubmission"
}

extension HomeworkSubmission: Marshaling {
    public func marshaled() -> [String: Any] {
        return [
            "_id": self.id,
            "schoolId": self.student.schoolId,
            "studentId": self.student.id,
            "homeworkId": self.homework.id,
            "comment": self.comment
        ]
    }
}
