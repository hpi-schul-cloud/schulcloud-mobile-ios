//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import Result
import UIKit

let placeholder = "Enter your comment here"

final class HomeworkSubmitViewController: UIViewController {

    @IBOutlet private weak var progressContainer: UIView!
    @IBOutlet private weak var progressView: UIProgressView!

    @IBOutlet private weak var contentView: UIScrollView!
    @IBOutlet private weak var commentLabel: UILabel!
    @IBOutlet private weak var commentField: UITextView!

    @IBOutlet private weak var filesLabel: UILabel!
    @IBOutlet private weak var filesTableView: UITableView!

    @IBOutlet private weak var addFilesButton: UIButton!
    @IBOutlet private weak var applyChangesButton: UIButton!
    @IBOutlet private weak var discardChangesButton: UIButton!
    @IBOutlet private weak var submissionActionStackView: UIStackView!

    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!

    fileprivate typealias FileID = String
    fileprivate typealias Filename = String

    var submission: Submission!

    fileprivate var files: [FileID] = []

    fileprivate let fileSync = FileSync.default
    fileprivate let writingContext = CoreDataHelper.persistentContainer.newBackgroundContext()
    fileprivate var writableSubmission: Submission!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.filesTableView.delegate = self
        self.filesTableView.dataSource = self

        self.commentField.delegate = self
        self.commentField.textContainerInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        self.writableSubmission = self.writingContext.typedObject(with: self.submission.objectID)

        if self.submission.homework.dueDate <= Date() {
            self.submissionActionStackView.isHidden = true
            self.addFilesButton.isHidden = true
            self.commentField.isEditable = false
        }

        let tintColor = UIApplication.shared.delegate!.window!!.tintColor

        var (r, g, b): (CGFloat, CGFloat, CGFloat) = (0, 0, 0)
        tintColor?.getRed(&r, green: &g, blue: &b, alpha: nil)

        self.addFilesButton.layer.cornerRadius = 4.0
        self.addFilesButton.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 0.3)

        self.submissionActionStackView.arrangedSubviews.forEach { button in
            button.layer.cornerRadius = 4.0
            button.clipsToBounds = true
        }

        self.applyChangesButton.backgroundColor = tintColor

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        self.contentView.addGestureRecognizer(tapRecognizer)

        self.updateState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableViewHeightConstraint.constant = self.filesTableView.contentSize.height
        self.contentView.setNeedsLayout()
    }

    @objc func dismissKeyboard(_ sender: Any?) {
        self.commentField.resignFirstResponder()
    }

    @IBAction func applyChanges(_ sender: Any) {
        self.commentField.resignFirstResponder()
        SubmissionHelper.saveSubmission(item: self.writableSubmission).onSuccess(DispatchQueue.main.context) {[unowned self] _ in
            // TODO: deal with save result
            switch self.writingContext.saveWithResult() {
            case .success:
                self.showAlert(title: "Success", message: "Your submission has been updated successfuly")
            case .failure(let error):
                print("error saving submission: \(error)")
            }

            self.submission = CoreDataHelper.viewContext.typedObject(with: self.submission.objectID)
        }.onFailure(DispatchQueue.main.context) { error in
            self.writingContext.rollback()
            self.showAlert(title: "Error", message: "Your submission failed to be updated, reason: \(error.localizedDescription)")
        }.onComplete(DispatchQueue.main.context) { _ in
            self.updateState()
        }
    }

    @IBAction func discardChanges(_ sender: Any) {
        let alertController = UIAlertController(title: "Are you sure?",
                                                message: "You will discard all the changes made to your submission.",
                                                preferredStyle: .alert)
        let discardAction = UIAlertAction(title: "Discard Changes", style: .destructive) { [unowned self] _ in
            self.writingContext.rollback()
            self.updateState()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        [cancelAction, discardAction].forEach { alertController.addAction($0) }

        self.present(alertController, animated: true)
    }

    @IBAction func submitFile(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self

        let actionController = UIAlertController()
        let cameraAction = UIAlertAction(title: "Taking a picture", style: .default) { [unowned self] _ in
                picker.sourceType = .camera
            picker.allowsEditing = true
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.showsCameraControls = true
            self.present(picker, animated: true)
        }

        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { [unowned self] _ in
            picker.sourceType = .savedPhotosAlbum
            picker.allowsEditing = false

            self.present(picker, animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        [cameraAction, libraryAction, cancelAction].forEach { actionController.addAction($0) }

        self.present(actionController, animated: true)
    }

    fileprivate func updateState() {
        var fileIDs = Set<String>(self.submission.files.map { $0.id })
        fileIDs.formUnion(self.writableSubmission.files.map { $0.id })
        self.files = [String](fileIDs).sorted()

        self.commentField.text = self.writableSubmission.comment ?? placeholder
        self.filesTableView.reloadData()
        self.tableViewHeightConstraint.constant = self.filesTableView.contentSize.height
        self.contentView.setNeedsLayout()
    }

    func show(error: Error) {
        let alertController = UIAlertController(title: "Something unexpected occured", message: error.localizedDescription, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
    }
}

extension HomeworkSubmitViewController: UITableViewDelegate {

}

extension HomeworkSubmitViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let fileId = self.files[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell") {
            let color: UIColor
            let filename: String

            if let file = self.writableSubmission.files.first(where: { $0.id == fileId }) {
                if self.submission.files.contains(where: { $0.id == fileId }) {
                    color = UIColor.black
                } else {
                    color = UIColor.green
                }

                filename = file.name
            } else {
                color = UIColor.red
                filename = self.submission.files.first { $0.id == fileId }?.name ?? ""
            }

            cell.textLabel?.text = filename
            cell.textLabel?.textColor = color
            return cell
        }

        fatalError("No cell found")
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let removeAction = UITableViewRowAction(style: .destructive, title: "Remove") {[unowned self] _, indexPath in
            let fileID = self.files[indexPath.row]
            if let file = self.writableSubmission.files.first(where: { $0.id == fileID }) {
                self.unlink(file: file, from: self.submission)
            }

            self.updateState()
        }

        return [removeAction]
    }
}

// MARK: - Submission writting
extension HomeworkSubmitViewController {
    func link(file: File, to submission: Submission) {
        let fileObjectId = file.objectID
        self.writingContext.performAndWait {
            let file = self.writingContext.typedObject(with: fileObjectId) as File
            self.writableSubmission.files.insert(file)
        }
    }

    fileprivate  func unlink(file: File, from submission: Submission) {
        let fileObjectID = file.objectID
        self.writingContext.performAndWait {
            let file = self.writingContext.typedObject(with: fileObjectID) as File
            self.writableSubmission.files.remove(file)
        }
    }

    fileprivate func write(content: String, to submission: Submission) {
        self.writingContext.performAndWait { [unowned self] in
            self.writableSubmission.comment = content
        }
    }
}

// MARK: Image Picker
extension HomeworkSubmitViewController: UINavigationControllerDelegate {

}

extension HomeworkSubmitViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let urlKey: UIImagePickerController.InfoKey
        if #available(iOS 11.0, *) {
            urlKey = .imageURL
        } else {
            urlKey = .referenceURL
        }

        guard let imageURL = info[urlKey] as? URL else {
            fatalError("Need image URL")
        }

        let destURL: URL
        do {
            destURL = try FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true).appendingPathComponent(imageURL.lastPathComponent)
            try FileManager.default.copyItem(at: imageURL, to: destURL)
        } catch let error {
            print("Error dealing with image file: \(error)")
            picker.dismiss(animated: true)
            return
        }

        picker.dismiss(animated: true) {
            self.progressContainer.isHidden = false
            self.view.bringSubviewToFront(self.progressContainer)
            let progress = self.fileSync.postFile(at: destURL, owner: nil, parentId: nil) { [unowned self] result in
                switch result {
                case .failure(let error):
                    try? FileManager.default.removeItem(at: destURL)
                    DispatchQueue.main.async {
                        self.show(error: error)
                    }
                case .success(let file):
                    try? FileManager.default.moveItem(at: destURL, to: file.localURL)
                    self.link(file: file, to: self.submission)
                }
                DispatchQueue.main.async {
                    self.updateState()
                    self.progressContainer.isHidden = true
                }
            }
            self.progressView.observedProgress = progress
        }
    }
}

// MARK: - TextView Delegate
extension HomeworkSubmitViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder {
            textView.text = ""
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let content = textView.text ?? ""

        if let comment = submission.comment {
            if comment != content { write(content: content, to: submission) }
        } else {
            write(content: content, to: submission)
        }

        if content == "" {
            textView.text = placeholder
        }
    }
}

// MARK: - Helper
extension HomeworkSubmitViewController {
    fileprivate func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
    }
}
