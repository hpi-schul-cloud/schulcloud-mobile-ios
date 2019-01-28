//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//
import BrightFutures
import Common
import Marshal
import Result
import UIKit

class HomeworkDetailViewController: UIViewController {

    @IBOutlet private weak var subjectLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var coloredStrip: UIView!
    @IBOutlet private weak var dueLabel: UILabel!

    @IBOutlet private weak var submitHomeworkButton: UIButton!

    var homework: Homework?

    let fileSync = FileSync.default

    override func viewDidLoad() {
        super.viewDidLoad()
        self.coloredStrip.layer.cornerRadius = self.coloredStrip.frame.size.height / 2.0
        guard let homework = self.homework else { return }

        if homework.submission == nil {
            let json: [String: Any] = [
                "schoolId": Globals.currentUser!.schoolId,
                "studentId": Globals.currentUser!.id,
                "homeworkId": homework.id,
                "teamMembers": [Globals.currentUser!.id] as Any,
            ]

            SubmissionHelper.syncSubmission(studentId: Globals.currentUser!.id, homeworkId: homework.id).flatMap { submissions -> Future<Submission, SCError> in
                if submissions.objectIds.isEmpty {
                    return SubmissionHelper.createSubmission(json: json).map({ result -> Submission in
                        return CoreDataHelper.viewContext.typedObject(with: result.objectId) as Submission
                    })
                }

                if submissions.objectIds.count > 1 {
                    return Future(error: SCError.coreDataMoreThanOneObjectFound)
                }

                return Future(value: CoreDataHelper.viewContext.typedObject(with: submissions.objectIds.first!))
            }.onSuccess { submission in
                DispatchQueue.main.async {
                    self.configure(for: self.homework!)
                }
            }.onFailure { error in
                print("Failed to sync or create submission, error: %@", error)
            }
        }
        self.configure(for: homework)
    }

    func configure(for homework: Homework) {
        self.subjectLabel.text = homework.courseName.uppercased()
        self.titleLabel.text = homework.name
        self.dueLabel.text = Homework.dateTimeFormatter.string(from: homework.dueDate)
        self.coloredStrip.backgroundColor = homework.color

        let title = homework.submission != nil ? "Submit file(s) (\(homework.submission!.files.count) submitted)" : "Submit file(s)"
        self.submitHomeworkButton.titleLabel?.text = title

        self.contentLabel.attributedText = HTMLHelper.default.attributedString(for: homework.descriptionText)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showSubmission",
            let controller = segue.destination as? HomeworkSubmitViewController else {
                return
        }
        controller.submission = self.homework?.submission
    }
}
