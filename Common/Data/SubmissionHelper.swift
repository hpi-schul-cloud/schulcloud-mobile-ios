//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import SyncEngine

public struct SubmissionHelper {

    public static func syncAllSubmissions() -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest: NSFetchRequest<Submission> = Submission.fetchRequest()
        let query = MultipleResourcesQuery(type: Submission.self)
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }

    public static func syncSubmission(with id: String) -> Future<SyncEngine.SyncSingleResult, SCError> {
        let fetchRequest: NSFetchRequest<Submission> = Submission.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        var query = SingleResourceQuery(type: Submission.self, id: id)
        query.include("fileIds")
        return SyncHelper.syncResource(withFetchRequest: fetchRequest, withQuery: query)
    }

    public static func syncSubmission(studentId: String, homeworkId: String) -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest: NSFetchRequest<Submission> = Submission.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "homework.id == %@ AND studentId == %@", homeworkId, studentId)
        var query = MultipleResourcesQuery(type: Submission.self)
        query.include("fileIds")
        query.addFilter(forKey: "homeworkId", withValue: homeworkId)
        query.addFilter(forKey: "studentId", withValue: studentId)

        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }

    public static func updateSubmission(with id: String) -> Future<Void, SCError> {
        var result: Future<Void, SCError> = Future(value: ())
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        context.performAndWait {
            let fetchrequest: NSFetchRequest<Submission> = Submission.fetchRequest()
            fetchrequest.predicate = NSPredicate(format: "id == %@", id)
            guard let submission = context.fetchSingle(fetchrequest).value else {
                result = Future(error: .coreDataObjectNotFound)
                return
            }
            result = SyncHelper.saveResource(submission)
        }
        return result
    }

    public static func saveSubmission(item: Submission) -> Future<Void, SCError> {
        return SyncHelper.saveResource(item)
    }

    public static func createSubmission(json: [String: Any]) -> Future<SyncEngine.SyncSingleResult, SCError> {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            return Future(error: .jsonSerialization("Can't serialize Submission"))
        }
        return SyncHelper.createResource(ofType: Submission.self, withData: data)
    }
}
