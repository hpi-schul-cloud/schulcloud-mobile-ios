//
//  HomeworkSubmissionHelper.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 27.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import BrightFutures
import CoreData

extension HomeworkSubmission {
    
    func upload() -> Future<Void, SCError> {
        let body = self.marshaled()
        return ApiHelper.request("submissions", method: .post, parameters: body).responseJSONFuture()
            .recoverWith { _ in ApiHelper.request("submissions/\(self.id)", method: .patch, parameters: body).responseJSONFuture() }
            .asVoid()
    }
}

struct HomeworkSubmissionHelper {
    static func save(for homework: Homework, existing: HomeworkSubmission?, submissionText: String) -> Future<Void, SCError> {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = managedObjectContext
        let submission = existing ?? HomeworkSubmission(context: managedObjectContext)
        submission.comment = submissionText
        submission.homework = homework
        return User.getCurrent(inContext: context)
            .andOnSuccess { submission.student = $0 }
            .flatMap { _ in submission.upload() }
            .onSuccess {
                do {
                    try context.save()
                    try managedObjectContext.save()
                } catch let error {
                    log.error(error.description)
                }
            }
    }
}
