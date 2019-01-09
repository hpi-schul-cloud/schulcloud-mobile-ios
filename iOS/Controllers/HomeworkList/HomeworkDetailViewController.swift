//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

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
            let picker = UIImagePickerController()
            picker.sourceType = .savedPhotosAlbum
            picker.allowsEditing = false

            self.present(picker, animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        [cameraAction, libraryAction, cancelAction].forEach { actionController.addAction($0) }
        self.present(actionController, animated: true)
    }
}

extension HomeworkDetailViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {

    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // TODO: Save locally, prepare for upload
        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        do {
            // TOoDO: find better submission file naem
            let destURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("picture_submission_\(self.homework?.id ?? "")")
            let jpegData = image.jpegData(compressionQuality: 0.7)
            try jpegData?.write(to: destURL, options: .withoutOverwriting)
        } catch _ {

        }

        // Schedule upload of image
    }
}
