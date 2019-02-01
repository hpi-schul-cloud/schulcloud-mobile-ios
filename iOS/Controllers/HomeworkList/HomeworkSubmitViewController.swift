//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import Result
import UIKit

final class HomeworkSubmitViewController: UIViewController {

    @IBOutlet weak var contentView: UIScrollView!
    @IBOutlet weak var commentField: UITextView!

    @IBOutlet weak var filesTableView: UITableView!

    @IBOutlet weak var applyChange: UIButton!
    @IBOutlet weak var discardChange: UIButton!

    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!

    var submission: Submission!
    var files: [File] = []

    fileprivate let fileSync = FileSync.default
    fileprivate let writingContext = CoreDataHelper.persistentContainer.newBackgroundContext()
    fileprivate var writableSubmission: Submission!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.files = Array(self.submission.files)

        self.filesTableView.delegate = self
        self.filesTableView.dataSource = self


        self.commentField.text = self.submission.comment ?? ""
        self.commentField.delegate = self

        self.writableSubmission = self.writingContext.typedObject(with: self.submission.objectID) as Submission

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableViewHeightConstraint.constant = self.filesTableView.contentSize.height
        self.contentView.setNeedsLayout()
    }

    @IBAction func applyChanges(_ sender: Any) {
        SubmissionHelper.saveSubmission(item: self.writableSubmission).onSuccess(DispatchQueue.main.context) {[unowned self] _ in
            //TODO: deal with save result
            switch self.writingContext.saveWithResult() {
            case .success(_):
                self.showAlert(title: "Sucess", message: "Your submission has been updated successfuly")
            case .failure(let error):
                print("error saving submission: \(error)")
            }
        }.onFailure(DispatchQueue.main.context) { error in
            self.writingContext.rollback()
            self.showAlert(title: "Error", message: "Your submission failed to be updated, reason: \(error.localizedDescription)")
        }
    }

    @IBAction func discardChanges(_ sender: Any) {
        self.writingContext.rollback()
    }

    @IBAction func submitFile(_ sender: Any) {
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

extension HomeworkSubmitViewController: UITableViewDelegate {

}

extension HomeworkSubmitViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.submission.files.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let file = self.files[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell") {
            cell.textLabel?.text = file.name
            return cell
        }
        fatalError()
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let removeAction = UITableViewRowAction(style: .destructive, title: "Remove") {[unowned self] (action, indexPath) in
            let files = Array(self.submission?.files ?? [])
            let file = files[indexPath.row]
            self.unlink(file: file, from: self.submission)
            //TODO: Handle unlinked of file to submission
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
                    self.filesTableView.reloadData()
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
