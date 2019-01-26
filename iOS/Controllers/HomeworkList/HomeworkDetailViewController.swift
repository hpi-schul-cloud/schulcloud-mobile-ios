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

    @IBAction func submitHomework(_ sender: Any) {
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showSubmission",
            let controller = segue.destination as? HomeworkSubmitViewController else {
                return
        }
        controller.submission = self.homework?.submission
    }
}

extension HomeworkDetailViewController: UINavigationControllerDelegate {

}

extension HomeworkDetailViewController: UIImagePickerControllerDelegate {
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
            destURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("picture_submission_\(self.homework?.id ?? "")_\(UUID().uuidString).jpeg")
            let jpegData = image.jpegData(compressionQuality: 0.7)
            try jpegData?.write(to: destURL, options: .withoutOverwriting)
        } catch let error {
            print(error)
            dismissPicker()
            return
        }

        self.postFile(at: destURL) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let file):
                self.link(file: file, to: self.homework!.submission!) { (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(_):
                        print("Success")
                    }
                    DispatchQueue.main.async {
                        self.configure(for: self.homework!)
                    }
                    dismissPicker()
                }
            }
        }
    }

    func link(file: File, to submission: Submission, completionHandler: @escaping (Result<Void, SCError>) -> Void ) {
        let fileObjectId = file.objectID
        let submissionObjectID = submission.objectID
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        context.performAndWait {
            let file = context.typedObject(with: fileObjectId) as File
            let submission = context.typedObject(with: submissionObjectID) as Submission
            submission.files.insert(file)
            context.saveWithResult()
            SubmissionHelper.saveSubmission(item: submission).onComplete(callback: completionHandler)
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
            flatname = signedURL.header[.flatName]!
            thumbnailURL = signedURL.header[.thumbnail]!

            let (task, future) = self.upload(fileAt: url, to: signedURL.url, mimeType: type)
            task.resume()
            return future
        }.flatMap { _ -> Future<[String: Any], SCError> in
            let (task, future) = self.createFileMetadata(at: remoteURL, mimeType: type, size: size, flatName: flatname, thumbnailURL: URL(string: thumbnailURL)!)
            task?.resume()
            return future
        }.flatMap { json -> Result<File, SCError> in
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

        let task = self.fileSync.upload(id: "homework_upload_\(self.homework?.id ?? "")", remoteURL: remoteURL, fileToUploadURL: url, mimeType: mimeType) {
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
