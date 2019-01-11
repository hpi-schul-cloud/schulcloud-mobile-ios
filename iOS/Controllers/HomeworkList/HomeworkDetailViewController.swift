//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import Marshal
import UIKit

fileprivate let homeworkUploadSession: URLSession = {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    return session
}()

fileprivate let homeworkMetadtaSession: URLSession = {
    return URLSession(configuration: URLSessionConfiguration.ephemeral)
}()

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
        

        var request = URLRequest(url: URL(string: "https://api.schul-cloud.org/fileStorage/signedUrl")! )
        request.httpMethod = "POST"
        request.addValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let userURL = URL(string: "users/\(Globals.currentUser?.id ?? "")")!
        let remoteURL = userURL.appendingPathComponent(destURL.lastPathComponent)
        let parameters: Any = [
            "path": remoteURL.absoluteString.removingPercentEncoding!,
            "fileType": "image/jpeg",
            "action": "putObject",
            ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            dismissPicker()
            return
        }
        request.httpBody = jsonData

        homeworkMetadtaSession.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse else {
                print(error)
                dismissPicker()
                return
            }
            guard 200 ... 299 ~= response.statusCode else {
                dismissPicker()
                return
            }

            guard let data = data,
                  let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments )) as! MarshaledObject? else {
                    dismissPicker()
                    return
            }

            let url: URL = try! json.value(for: "url")
            let header: [String: String] = try! json.value(for: "header")

            let flatname: String = header["x-amz-meta-flat-name"]!
            let thumbnailURL: String = header["x-amz-meta-thumbnail"]!

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"

            homeworkUploadSession.uploadTask(with: request, fromFile: destURL, completionHandler: { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    dismissPicker()
                    return
                }
                guard 200 ... 299 ~= response.statusCode else {
                    dismissPicker()
                    return
                }

                let parameters: [String: Any] = [
                    "key":  remoteURL.absoluteString.removingPercentEncoding!,
                    "path": remoteURL.deletingLastPathComponent().absoluteString.removingPercentEncoding!,
                    "name": remoteURL.lastPathComponent.removingPercentEncoding!,
                    "type": "image/jpeg",
                    "size": try! FileManager.default.attributesOfItem(atPath: destURL.path)[FileAttributeKey.size] as! Int,
                    "flatFileName": flatname,
                    "thumbnail": thumbnailURL,
                    "studentCanEdit": false,
                    "schoolId": Globals.currentUser!.schoolId,
                ]

                var request = URLRequest(url: URL(string: "https://api.schul-cloud.org/files/file/")! )
                request.httpMethod = "POST"
                request.addValue(Globals.account!.accessToken!, forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

                homeworkMetadtaSession.dataTask(with: request) { data, response, error in
                    guard let response = response as? HTTPURLResponse else {
                        dismissPicker()
                        return
                    }
                    guard 200 ... 299 ~= response.statusCode else {
                        dismissPicker()
                        return
                    }
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                            dismissPicker()
                            return
                    }

                    print(json)

                }.resume()
            }).resume()
        }.resume()
        // Schedule upload of image
    }
}
