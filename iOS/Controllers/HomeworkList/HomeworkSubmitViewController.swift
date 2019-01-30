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

final class HomeworkSubmitTableFooterView: UIView {

}

final class HomeworkSubmitViewController: UITableViewController {

    private enum Section: Int, CaseIterable {
        case comment = 0
        case files
        case teacherComment
    }

    var submission: Submission?
    fileprivate let fileSync = FileSync.default
    fileprivate let writtingContext = CoreDataHelper.persistentContainer.newBackgroundContext()

    @IBAction func applyChanges(_ sender: Any) {
        switch self.writtingContext.saveWithResult() {
        case .failure(let error):
            //TODO Display error
            print("Error saving changes: \(error)")
        case .success(_):
            SubmissionHelper.saveSubmission(item: self.submission!)
        }
    }

    @IBAction func discardChanges(_ sender: Any) {
        self.writtingContext.rollback()
    }

    override func viewDidLoad() {
        let nib = UINib(nibName: "HomeworkSubmitFileButton", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: addFileFooterIdentifier)
        self.tableView.keyboardDismissMode = .onDrag
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        var count = 2
        if self.submission?.gradeComment?.isEmpty == false { count += 1 }
        return count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .comment:
            return "Comments"
        case .files:
            return "Files"
        case .teacherComment:
            return "Teacher's comment"
        }
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
            case .comment:
                text = self.submission?.comment
            case .files:
                text = files[indexPath.row].name
            case .teacherComment:
                cell.textLabel?.text = self.submission?.gradeComment
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

        // TODO: implement action
        let removeAction = UITableViewRowAction(style: .destructive, title: "Remove") { (action, indexPath) in

        }

        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in

        }
        return [removeAction, deleteAction]
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == Section.files.rawValue else { return nil }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "addFileFooter") as? HomeworkSubmitFileFooterView else { return nil }
        if view.submitButton.target(forAction: #selector(submitFile), withSender: nil) == nil {
            view.submitButton.addTarget(self, action: #selector(submitFile), for: .touchUpInside)
        }
        return view
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

// MARK: - Submission writting
extension HomeworkSubmitViewController {

}

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

        // TODO: Save locally, prepare for upload
        guard let image = info[.originalImage] as? UIImage  else {
            fatalError()
        }

        // TOoDO: find better submission file naem
        let destURL: URL
        do {
            destURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("picture_submission_\(self.submission?.id ?? "")_\(UUID().uuidString).jpeg")
            let jpegData = image.jpegData(compressionQuality: 0.7)
            try jpegData?.write(to: destURL, options: .withoutOverwriting)
        } catch let error {
            print(error)
            dismissPicker()
            return
        }

        self.postFile(at: destURL) { [unowned self] result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let file):
                self.link(file: file, to: self.submission!) { (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(_):
                        print("Success")
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    dismissPicker()
                }
            }
        }
    }

    func link(file: File, to submission: Submission, completionHandler: @escaping (Result<Void, SCError>) -> Void ) {
        let fileObjectId = file.objectID
        let submissionObjectID = submission.objectID
        self.writtingContext.performAndWait {
            let file = self.writtingContext.typedObject(with: fileObjectId) as File
            let submission = self.writtingContext.typedObject(with: submissionObjectID) as Submission
            submission.files.insert(file)
        }
    }

    func postFile(at url: URL, completionHandler: @escaping (Result<File, SCError>) -> Void) {
        let userURL = URL(string: "users/\(Globals.currentUser?.id ?? "")")!
        let remoteURL = userURL.appendingPathComponent(url.lastPathComponent)

        let size: Int = ((try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? Int) ?? 0

        var flatname: String = ""
        var thumbnailURL: String = ""
        let type: String = "image/jpeg"

        let (task, future) = self.signedURL(resourceAt: remoteURL, mimeType: type, forUpload: true)
        future.flatMap { signedURL -> Future<Void, SCError> in
            // Upload file
            flatname = signedURL.header[.flatName]!
            thumbnailURL = signedURL.header[.thumbnail]!

            let (task, future) = self.upload(fileAt: url, to: signedURL.url, mimeType: type)
            task.resume()
            return future
        }.flatMap { _ -> Future<[String: Any], SCError> in
            // Remotely create the file metadtas
            let (task, future) = self.createFileMetadata(at: remoteURL, mimeType: type, size: size, flatName: flatname, thumbnailURL: URL(string: thumbnailURL)!)
            task?.resume()
            return future
        }.flatMap { json -> Result<File, SCError> in
            // Create the local file metadata
            let context = CoreDataHelper.persistentContainer.newBackgroundContext()
            return context.performAndWait { () -> Result<File, SCError> in
                guard let userDirectory = File.by(id: FileHelper.userDirectoryID, in: context) else {
                    return .failure(SCError.coreDataMoreThanOneObjectFound)
                }
                do {
                    let file = try File.createOrUpdate(inContext: context, parentFolder: userDirectory, isDirectory: false, data: json)
                    context.saveWithResult()
                    return .success(file)
                } catch let error as SCError {
                    return .failure(error)
                } catch let error {
                    return .failure(SCError.other(error.localizedDescription))
                }
            }
        }.onComplete(callback: completionHandler)
        task?.resume()
    }

    private func signedURL(resourceAt url: URL, mimeType: String, forUpload: Bool) -> (URLSessionTask?, Future<SignedURLInfo, SCError>) {
        let promise = Promise<SignedURLInfo, SCError>()
        let task = self.fileSync.signedURL(resourceAt: url, mimeType: mimeType, forUpload: forUpload) { promise.complete($0) }
        return (task, promise.future)
    }

    private func upload(fileAt url: URL, to remoteURL: URL, mimeType: String) -> (URLSessionTask, Future<Void, SCError>) {
        let promise = Promise<Void, SCError>()

        let task = self.fileSync.upload(id: "submission_upload_\(self.submission?.id ?? "")", remoteURL: remoteURL, fileToUploadURL: url, mimeType: mimeType) {
            promise.complete($0)
        }
        return (task, promise.future)
    }

    private func createFileMetadata(at: URL, mimeType: String, size: Int, flatName: String, thumbnailURL: URL) -> (URLSessionTask?, Future<[String: Any], SCError>) {
        let promise = Promise<[String: Any], SCError>()
        let task = self.fileSync.createFileMetadata(at: at, mimeType: mimeType, size: size, flatName: flatName, thumbnailURL: thumbnailURL) { promise.complete($0) }
        return (task, promise.future)
    }
}

extension HomeworkSubmitViewController: UITextViewDelegate {

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let submission = self.submission else { return }

        func write(content: String) {
            let subObjectID = submission.objectID
            self.writtingContext.performAndWait { [unowned self] in
                let sub = self.writtingContext.typedObject(with: subObjectID) as Submission
                sub.comment = content
            }
        }

        let content = textView.text ?? ""

        if let comment = submission.comment {
            if comment != content { write(content: content) }
        } else {
            write(content: content)
        }
    }
}
