//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import Result
import UIKit

fileprivate let addFileFooterIdentifier = "addFileFooter"

final class HomeworkSubmitStudentCommentCell: UITableViewCell {
    @IBOutlet var commentField: UITextView!
}

final class HomeworkSubmitViewController: UITableViewController {

    var submission: Submission!

    private enum Section: Int, CaseIterable {
        case comment = 0
        case files
        case teacherComment

        var name: String {
            switch self {
            case .comment:
                return "Comments"
            case .files:
                return "Files"
            case .teacherComment:
                return "Teacher's comment"
            }
        }
    }

    fileprivate let fileSync = FileSync.default
    fileprivate let writtingContext = CoreDataHelper.persistentContainer.newBackgroundContext()
    fileprivate var writableSubmission: Submission!

    override func viewDidLoad() {
        self.writableSubmission = self.writtingContext.typedObject(with: self.submission.objectID)

        let nib = UINib(nibName: "HomeworkSubmitFileButton", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: addFileFooterIdentifier)
        self.tableView.keyboardDismissMode = .onDrag
    }

// MARK: - User action
    @IBAction func applyChanges(_ sender: Any) {
        switch self.writtingContext.saveWithResult() {
        case .failure(let error):
            //TODO Display error
            print("Error saving changes: \(error)")
        case .success(_):

            SubmissionHelper.saveSubmission(item: self.writableSubmission).onSuccess(DispatchQueue.main.context) {[unowned self] _ in
                //TODO: deal with save result
                self.writtingContext.saveWithResult()
                self.showAlert(title: "Sucess", message: "Your submission has been updated successfuly")
            }.onFailure(DispatchQueue.main.context) { error in
                self.writtingContext.rollback()
                self.showAlert(title: "Error", message: "Your submission failed to be updated, reason: \(error.localizedDescription)")
            }
        }
    }

    @IBAction func discardChanges(_ sender: Any) {
        self.writtingContext.rollback()
    }

    @objc func submitFile() {
        let picker = UIImagePickerController()
        picker.delegate = self

        let actionController = UIAlertController()
        let cameraAction = UIAlertAction(title: "Taking a picture", style: .default) { [unowned self] action in

            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.showsCameraControls = true
            self.present(picker, animated: true)
        }

        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { [unowned self] action in
            picker.sourceType = .savedPhotosAlbum
            picker.allowsEditing = false

            self.present(picker, animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        [cameraAction, libraryAction, cancelAction].forEach { actionController.addAction($0) }

        self.present(actionController, animated: true)
    }
}

// MARK: - TableView Delegate / Datasource
extension HomeworkSubmitViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        var count = 2
        if self.submission?.gradeComment?.isEmpty == false { count += 1 }
        return count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        return section.name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { fatalError() }
        switch section {
        case .comment:
            return 1
        case .files:
            return submission?.files.count ?? 0
        case .teacherComment:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let section = Section(rawValue: section), section == .files else { return 0.0 }
        return 44
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { fatalError() }

        switch section {
        case .comment:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell")! as! HomeworkSubmitStudentCommentCell
            if cell.commentField.text.isEmpty { cell.commentField.text = self.submission?.comment ?? "" }
            cell.commentField.delegate = self
            return cell
        default:
            var maybeCell = tableView.dequeueReusableCell(withIdentifier: "homeworkCell")
            if maybeCell == nil {
                maybeCell = UITableViewCell(style: .default, reuseIdentifier: "homeworkCell")
            }
            let cell = maybeCell!

            let files = Array(self.submission?.files ?? [])

            var text: String? = nil
            switch section {
            case .files:
                text = files[indexPath.row].name
            case .teacherComment:
                cell.textLabel?.text = self.submission?.gradeComment
            default:
                break
            }

            cell.textLabel?.text = text
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.files.rawValue
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard indexPath.section == Section.files.rawValue else { return nil }

        let removeAction = UITableViewRowAction(style: .destructive, title: "Remove") {[unowned self] (action, indexPath) in
            let files = Array(self.submission?.files ?? [])
            let file = files[indexPath.row]
            self.unlink(file: file, from: self.submission)
        }

        return [removeAction]
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == Section.files.rawValue else { return nil }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "addFileFooter") as? HomeworkSubmitFileFooterView else { return nil }
        if view.submitButton.target(forAction: #selector(submitFile), withSender: nil) == nil {
            view.submitButton.addTarget(self, action: #selector(submitFile), for: .touchUpInside)
        }
        return view
    }

}

// MARK: - Submission writting
extension HomeworkSubmitViewController {
    func link(file: File, to submission: Submission) {
        let fileObjectId = file.objectID
        self.writtingContext.performAndWait {
            let file = self.writtingContext.typedObject(with: fileObjectId) as File
            self.writableSubmission.files.insert(file)
        }
    }

    fileprivate  func unlink(file: File, from submission: Submission) {
        let fileObjectID = file.objectID
        self.writtingContext.performAndWait {
            let file = self.writtingContext.typedObject(with: fileObjectID) as File
            self.writableSubmission.files.remove(file)
        }
    }

    fileprivate func write(content: String, to submission: Submission) {
        self.writtingContext.performAndWait { [unowned self] in
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        func dismissPicker() {
            DispatchQueue.main.async {
                picker.dismiss(animated: true)
            }
        }

        let urlKey: UIImagePickerController.InfoKey
        if #available(iOS 11.0, *) {
            urlKey = .imageURL
        } else {
            urlKey = .referenceURL
        }

        guard let imageURL = info[urlKey] as? URL else {
            fatalError()
        }

        let destURL: URL
        do {
            destURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(imageURL.lastPathComponent)
            try FileManager.default.copyItem(at: imageURL, to: destURL)
        } catch let error {
            print("Error dealing with image file: \(error)")
            dismissPicker()
            return
        }

        let userURL = URL(string: "users/\(Globals.currentUser?.id ?? "")")!
        let remoteURL = userURL.appendingPathComponent(destURL.lastPathComponent)

        self.fileSync.postFile(at: destURL, to: remoteURL) { [unowned self] result in
            switch result {
            case .failure(let error):
                try? FileManager.default.removeItem(at: destURL)
                print(error)
            case .success(let file):
                try? FileManager.default.moveItem(at: destURL, to: file.localURL)
                self.link(file: file, to: self.submission!)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                dismissPicker()
            }
        }
    }
}

// MARK: - TextView Delegate
extension HomeworkSubmitViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        let content = textView.text ?? ""

        if let comment = submission.comment {
            if comment != content { write(content: content, to: submission) }
        } else {
            write(content: content, to: submission)
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
