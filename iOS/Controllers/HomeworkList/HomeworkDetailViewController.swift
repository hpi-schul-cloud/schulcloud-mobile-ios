//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//
import BrightFutures
import Common
import Marshal
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
        if let homework = self.homework {
            self.configure(for: homework)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SubmissionHelper.syncSubmission(studentId: Globals.currentUser!.id,
                                        homeworkId: homework!.id).onComplete(DispatchQueue.main.context) { _ in
            self.homework = CoreDataHelper.viewContext.typedObject(with: self.homework!.objectID)
            self.configure(for: self.homework!)
        }
    }

    @IBAction private func submissionPressed(_ sender: UIButton) {
        guard self.homework!.submission == nil else {
            self.performSegue(withIdentifier: R.segue.homeworkDetailViewController.showSubmission, sender: nil)
            return
        }

        let json: [String: Any] = [
            "schoolId": Globals.currentUser!.schoolId,
            "studentId": Globals.currentUser!.id,
            "homeworkId": self.homework!.id,
            "teamMembers": [Globals.currentUser!.id] as Any,
        ]

        SubmissionHelper.syncSubmission(studentId: Globals.currentUser!.id,
                                        homeworkId: homework!.id).flatMap { submissions -> Future<Submission, SCError> in
            if submissions.objectIds.isEmpty {
                return SubmissionHelper.createSubmission(json: json).map { result -> Submission in
                    return CoreDataHelper.viewContext.typedObject(with: result.objectId) as Submission
                }
            }

            if submissions.objectIds.count > 1 {
                return Future(error: SCError.coreDataMoreThanOneObjectFound)
            }

            return Future(value: CoreDataHelper.viewContext.typedObject(with: submissions.objectIds.first!))
        }.onSuccess(DispatchQueue.main.context) { _ in
            self.performSegue(withIdentifier: R.segue.homeworkDetailViewController.showSubmission, sender: nil)
        }.onFailure(DispatchQueue.main.context) { error in
            let alertController = UIAlertController(title: "Error",
                                                    message: "Failed to create submission:\(error.localizedDescription)",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
            self.present(alertController, animated: true)
        }
    }

    func configure(for homework: Homework) {
        self.subjectLabel.text = homework.courseName.uppercased()
        self.titleLabel.text = homework.name
        self.dueLabel.text = Homework.dateTimeFormatter.string(from: homework.dueDate)
        self.coloredStrip.backgroundColor = homework.color

        self.submitHomeworkButton.isHidden = false

        let canView = Globals.currentUser!.permissions.contains(.submissionsView)
        let canEdit = Globals.currentUser!.permissions.contains(.submissionsEdit)
        let canCreate = Globals.currentUser!.permissions.contains(.submissionsCreate)

        let canInteract = [canView, canEdit, canCreate].reduce(true) { $0 && $1 }

        if canInteract {
            var title = ""
            if homework.dueDate > Date() {
                if homework.submission != nil {
                    if canEdit {
                        title = "Update Submission"
                    } else {
                        title = "View Submission"
                    }
                } else {
                    if canCreate {
                        title = "Create Submission"
                    } else {
                        self.submitHomeworkButton.isHidden = true
                    }
                }
            } else {
                if canView {
                    title = "View Submission"
                } else {
                    self.submitHomeworkButton.isHidden = true
                }
            }

            [UIControl.State.normal, .highlighted, .focused, .disabled].forEach { self.submitHomeworkButton.setTitle(title, for: $0) }
        } else {
            self.submitHomeworkButton.isHidden = true
        }

        self.contentLabel.attributedText = HTMLHelper.default.attributedString(for: homework.descriptionText).value
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueInfo = R.segue.homeworkDetailViewController.showSubmission(segue: segue) else { return }
        segueInfo.destination.submission = self.homework?.submission
    }
}
