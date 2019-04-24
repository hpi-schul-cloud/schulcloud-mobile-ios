//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
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

        self.filesTableView.register(UINib(nibName: "HomeworkSubmitFileCell", bundle: nil), forCellReuseIdentifier: "fileCell")

        self.filesTableView.delegate = self
        self.filesTableView.dataSource = self

        self.commentField.delegate = self
        self.commentField.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        self.commentField.textContainer.lineFragmentPadding = 0

        self.writableSubmission = self.writingContext.typedObject(with: self.submission.objectID)

        if self.submission.homework.dueDate <= Date() {
            self.addFilesButton.isHidden = true
            self.commentField.isEditable = false
        }

        self.addFilesButton.layer.cornerRadius = 4.0
        self.addFilesButton.backgroundColor = Brand.default.colors.primary

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        tapRecognizer.cancelsTouchesInView = false
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

    @objc func applyChanges(_ sender: Any) {
        self.commentField.resignFirstResponder()
        SubmissionHelper.saveSubmission(item: self.writableSubmission).onSuccess(DispatchQueue.main.context) {[unowned self] _ in
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

    @objc func discardChanges(_ sender: Any) {
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

    @IBAction private func submitFile(_ sender: Any) {

        let actionController = UIAlertController()
        let cameraAction = UIAlertAction(title: "Taking a picture", style: .default) { [unowned self] _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.showsCameraControls = true

            self.present(picker, animated: true)
        }

        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { [unowned self] _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .savedPhotosAlbum
            picker.allowsEditing = false
            self.present(picker, animated: true)
        }

        let addFileAction = UIAlertAction(title: "Personal files", style: .default) { [unowned self] _ in
            let fileStoryboard = UIStoryboard(name: "TabFiles", bundle: nil)
            let userFilesStoryboard = fileStoryboard.instantiateViewController(withIdentifier: "FolderVC") as! FilesViewController

            userFilesStoryboard.currentFolder = File.by(id: FileHelper.userDirectoryID, in: CoreDataHelper.viewContext)!
            userFilesStoryboard.delegate = self

            let navigationController = UINavigationController(rootViewController: userFilesStoryboard)
            let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                             target: userFilesStoryboard,
                                             action: #selector(FilesViewController.dismissController))
            userFilesStoryboard.navigationItem.setRightBarButton(cancelItem, animated: false)
            self.present(navigationController, animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        [cameraAction, libraryAction, addFileAction, cancelAction].forEach { actionController.addAction($0) }

        self.present(actionController, animated: true)
    }

    fileprivate func updateState() {
        var fileIDs = Set<String>(self.submission.files.map { $0.id })
        fileIDs.formUnion(self.writableSubmission.files.map { $0.id })
        self.files = [String](fileIDs).sorted()

        if !self.writableSubmission.changedValues().isEmpty {
            let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(applyChanges(_:)))
            let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(discardChanges(_:)))
            self.navigationItem.setRightBarButton(saveItem, animated: true)
            self.navigationItem.setLeftBarButton(cancelItem, animated: true)
        } else {
            self.navigationItem.setRightBarButton(nil, animated: true)
            self.navigationItem.setLeftBarButton(nil, animated: true)
        }

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

extension HomeworkSubmitViewController: FilePickerDelegate {
    func picked(item: File) {
        self.link(file: item, to: self.writableSubmission)
        self.updateState()
    }
}

extension HomeworkSubmitViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }

        let fileId = self.files[indexPath.row]
        let file = File.by(id: fileId, in: self.writingContext) ?? File.by(id: fileId, in: self.submission.managedObjectContext!)!
        let storyboard = UIStoryboard(name: "TabFiles", bundle: nil)
        let previewVC = storyboard.instantiateViewController(withIdentifier: "FilePreviewVC") as! FilePreviewViewController
        previewVC.item = file
        self.navigationController?.pushViewController(previewVC, animated: true)
    }
}

extension HomeworkSubmitViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let fileId = self.files[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! HomeworkSubmitFileCell
        let image: UIImage?
        let filename: String?

        if let file = self.writableSubmission.files.first(where: { $0.id == fileId }) {
            if self.submission.files.contains(where: { $0.id == fileId }) {
                image = UIImage(named: "cloud-done")
            } else {
                image = UIImage(named: "cloud-upload")
            }

            filename = file.name
        } else {
            image = UIImage(named: "cloud-outline")
            filename = self.submission.files.first { $0.id == fileId }?.name
        }

        cell.configure(withTitle: filename, image: image)

        return cell
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

        picker.dismiss(animated: true) {

            self.showRenameAlertController(originalName: imageURL.deletingPathExtension().lastPathComponent) { renameResult in
                switch renameResult {
                case .cancel:
                    break
                case.change(let newName):
                    let destURL: URL
                    do {
                        destURL = try FileManager.default.url(for: .cachesDirectory,
                                                              in: .userDomainMask,
                                                              appropriateFor: nil,
                                                              create: true).appendingPathComponent(newName).appendingPathExtension(imageURL.pathExtension)
                        try FileManager.default.copyItem(at: imageURL, to: destURL)
                    } catch let error {
                        print("Error dealing with image file: \(error)")
                        picker.dismiss(animated: true)
                        return
                    }

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

        self.updateState()
    }
}

// MARK: - Helper
extension HomeworkSubmitViewController {
    fileprivate func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
    }

    enum RenameAlertResult {
        case cancel
        case change(name: String)
    }

    fileprivate func showRenameAlertController(originalName: String, completionHandler: @escaping (RenameAlertResult) -> Void) {
        let alert = UIAlertController(title: "Enter a filename", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.setMarkedText(originalName, selectedRange: NSRange(location: 0, length: originalName.count))
        }

        let renameAction = UIAlertAction(title: "Ok", style: .default) { _ in
            completionHandler(.change(name:alert.textFields?.first?.text ?? originalName))
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(.cancel)
        }

        [renameAction, cancelAction].forEach { alert.addAction($0) }
        self.present(alert, animated: true)
    }

}
