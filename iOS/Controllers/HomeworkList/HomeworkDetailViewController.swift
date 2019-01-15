//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//
import BrightFutures
import Common
import Marshal
import Result
import UIKit

extension Result {
    func asVoid() -> Result<(), Error> {
        return self.map { _ in return () }
    }
}

class HomeworkDetailViewController: UIViewController {

    @IBOutlet private weak var subjectLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var contentLabel: UILabel!
    @IBOutlet private weak var coloredStrip: UIView!
    @IBOutlet private weak var dueLabel: UILabel!
    @IBOutlet weak var submitHomeworkButton: UIButton!

    var homework: Homework?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.coloredStrip.layer.cornerRadius = self.coloredStrip.frame.size.height / 2.0

        guard let homework = self.homework else { return }
        self.configure(for: homework)
    }

    func configure(for homework: Homework) {
        self.subjectLabel.text = homework.courseName.uppercased()
        self.titleLabel.text = homework.name
        self.dueLabel.text = Homework.dateTimeFormatter.string(from: homework.dueDate)
        self.coloredStrip.backgroundColor = homework.color

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
        
        postFile(at: destURL) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(_):
                print("Success")
            }
            dismissPicker()
        }
    }
}

fileprivate let homeworkUploadSession: URLSession = {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    return session
}()

fileprivate let homeworkMetadtaSession: URLSession = {
    return URLSession(configuration: URLSessionConfiguration.ephemeral)
}()

struct SignedURL {
    let url: URL
    let header: [String: String]

    struct HeaderKey {
        static let flatName: String = "x-amz-meta-flat-name"
        static let thumbnailURL: String = "x-amz-meta-thumbnail"
        static let name: String = "x-amz-meta-name"
        static let path: String = "x-amz-meta-path"
        static let contentType: String = "Content-Type"
    }
}

fileprivate func signedURL(at fileURL: URL, mimeType: String, action: String) -> Future<SignedURL, SCError> {
    let promise = Promise<SignedURL, SCError>()
    signedURL(at: fileURL, mimeType: mimeType, action: action) { promise.complete($0) }
    return promise.future
}

fileprivate func signedURL(at fileURL: URL, mimeType: String, action: String, completionHandler:@escaping (Result<SignedURL, SCError>) -> Void) {
    var request = URLRequest(url: URL(string: "https://api.schul-cloud.org/fileStorage/signedUrl")! )
    request.httpMethod = "POST"
    request.addValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let parameters: Any = [
        "path": fileURL.absoluteString.removingPercentEncoding!,
        "fileType": mimeType,
        "action": action,
        ]

    guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
        completionHandler(.failure(SCError.jsonSerialization("SignedURL serialization")))
        return
    }
    request.httpBody = jsonData

    homeworkMetadtaSession.dataTask(with: request) { data, response, error in
        guard let response = response as? HTTPURLResponse else {
            completionHandler(.failure(SCError.network(error)))
            return
        }
        guard 200 ... 299 ~= response.statusCode else {
            completionHandler(.failure(SCError.apiError(response.statusCode, "SignedURL")))
            return
        }

        guard let data = data,
            let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments )) as! MarshaledObject? else {
                completionHandler(.failure(.jsonDeserialization("SignedURL deserialization")) )
                return
        }

        let url: URL = try! json.value(for: "url")
        let header: [String: String] = try! json.value(for: "header")
        let result = SignedURL(url: url, header: header)
        completionHandler(.success(result))
        }.resume()
}

func uploadFile(at url: URL, to remoteURL: URL) -> Future<Void, SCError> {
    let promise = Promise<Void, SCError>()
    uploadFile(at: url, to: remoteURL) { promise.complete($0) }
    return promise.future
}

func uploadFile(at url: URL, to remoteURL: URL, completionHandler: @escaping (Result<Void, SCError>) -> Void) {
    var request = URLRequest(url: remoteURL)
    request.httpMethod = "PUT"

    homeworkUploadSession.uploadTask(with: request, fromFile: url, completionHandler: { (data, response, error) in
        guard let response = response as? HTTPURLResponse else {
            completionHandler(.failure(.network(error)))
            return
        }
        guard 200 ... 299 ~= response.statusCode else {
            completionHandler(.failure(.apiError(response.statusCode, "Upload")))
            return
        }
        completionHandler(.success(()))
    }).resume()
}

func createMetadata(key: String,
                    path: String,
                    name: String,
                    type: String,
                    size: Int,
                    flatfilename: String,
                    thumbnailURL: String) -> Future<[String: Any], SCError> {
    let promise = Promise<[String: Any], SCError>()
    createMetadata(key: key,
                   path: path,
                   name: name,
                   type: type,
                   size: size,
                   flatfilename: flatfilename,
                   thumbnailURL: thumbnailURL) { promise.complete($0) }
    return promise.future
}

func createMetadata(key: String,
                    path: String,
                    name: String,
                    type: String,
                    size: Int,
                    flatfilename: String,
                    thumbnailURL: String,
                    completionHandler: @escaping (Result<[String: Any], SCError>) -> Void) {

    let parameters: [String: Any] = [
        "key":  key.removingPercentEncoding!,
        "path": path.removingPercentEncoding!,
        "name": name.removingPercentEncoding!,
        "type": type,
        "size": size,
        "flatFileName": flatfilename,
        "thumbnail": thumbnailURL,
        "studentCanEdit": false,
        "schoolId": Globals.currentUser!.schoolId,
        ]

    var request = URLRequest(url: URL(string: "https://api.schul-cloud.org/files")! )
    request.httpMethod = "POST"
    request.addValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request .httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

    homeworkMetadtaSession.dataTask(with: request) { data, response, error in
        guard let response = response as? HTTPURLResponse else {
            completionHandler(.failure(.network(error)))
            return
        }
        guard 200 ... 299 ~= response.statusCode else {
            completionHandler(.failure(.apiError(response.statusCode, "File metadata")))
            return
        }
        guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any] else {
                completionHandler(.failure(.jsonDeserialization("File metadata deserialization")))
                return
        }
        completionHandler(.success(json))
    }.resume()
}



fileprivate func postFile(at url: URL, completionHandler: @escaping (Result<Void, SCError>) -> Void) {

    let userURL = URL(string: "users/\(Globals.currentUser?.id ?? "")")!
    let remoteURL = userURL.appendingPathComponent(url.lastPathComponent)

    let size: Int = ((try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? Int) ?? 0

    var flatname: String = ""
    var thumbnailURL: String = ""
    var type: String = ""
    var path: String = ""
    var name: String = ""
    var key: String = ""

    signedURL(at: remoteURL, mimeType: "image/jpeg", action: "putObject").flatMap { signedURL -> Future<Void, SCError> in
        flatname = signedURL.header[SignedURL.HeaderKey.flatName]!
        thumbnailURL = signedURL.header[SignedURL.HeaderKey.thumbnailURL]!
        type = signedURL.header[SignedURL.HeaderKey.contentType]!
        path = signedURL.header[SignedURL.HeaderKey.path]!
        name = signedURL.header[SignedURL.HeaderKey.name]!
        key = URL(string: path)!.appendingPathComponent(name).absoluteString.removingPercentEncoding!

        return uploadFile(at: url, to: signedURL.url)
    }.flatMap { _ -> Future<[String: Any], SCError> in
        return createMetadata(key: key, path: path, name: name, type: type, size: size, flatfilename: flatname, thumbnailURL: thumbnailURL)
    }flatMap { json -> Future<File, SCError> in
        return File
    }.onComplete{ completionHandler($0.asVoid()) }
}
