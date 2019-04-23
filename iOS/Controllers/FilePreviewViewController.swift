//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import Foundation
import QuickLook

protocol FilePickerDelegate: AnyObject {
    func picked(item: File)
}

class FilePreviewViewController: UIViewController {
    // MARK: Lifecycle
    @IBOutlet private var containerView: UIView!

    var item: File?
    weak var pickerDelegate: FilePickerDelegate?

    lazy var loadingViewController: LoadingViewController = {
        let storyboard = UIStoryboard(name: "TabFiles", bundle: nil)
        let loadingController = storyboard.instantiateViewController(withIdentifier: "LoadingVC") as! LoadingViewController
        loadingController.file = item
        loadingController.delegate = self
        loadingController.view.translatesAutoresizingMaskIntoConstraints = false
        return loadingController
    }()

    lazy var quicklookViewController: QLPreviewController = {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.title = self.item?.name
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        return previewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = item?.name
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }
        self.navigationController?.setToolbarHidden(true, animated: false)
        let flexibleFrontItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let flexibleBackItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(filePicked(_:)))
        self.setToolbarItems([flexibleFrontItem, doneItem, flexibleBackItem], animated: false)

        self.addChild(self.loadingViewController)
        self.loadingViewController.didMove(toParent: self)
        self.containerView.addSubview(self.loadingViewController.view)
        self.containerView.addConstraints(self.fullscreenConstraints(for: self.loadingViewController.view))
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
        super.viewWillDisappear(animated)
    }

    @objc func filePicked(_ sender: Any) {
        guard let item = self.item else { return }
        self.pickerDelegate?.picked(item: item)
        self.dismiss(animated: true)
    }

    private func fullscreenConstraints(for view: UIView) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[view]-(0)-|", options: [], metrics: nil, views: ["view": view]) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[view]-(0)-|", options: [], metrics: nil, views: ["view": view])
    }
}

extension FilePreviewViewController: LoadingViewControllerDelegate {
    func controllerDidFinishLoading(error: SCError?) {
        if let error = error {
            let alertController = UIAlertController(title: "Failed to show file",
                                                    message: "Something went wrong finding your file: \(error.debugDescription)",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default) { [unowned self] _ in
                self.navigationController?.popViewController(animated: true)
            }

            alertController.addAction(okAction)
            self.present(alertController, animated: true)
        } else {
            self.loadingViewController.removeFromParent()
            self.loadingViewController.didMove(toParent: nil)
            self.loadingViewController.view.removeFromSuperview()
            self.containerView.removeConstraints(self.loadingViewController.view.constraints)

            self.addChild(self.quicklookViewController)
            self.quicklookViewController.didMove(toParent: self)
            self.containerView.addSubview(self.quicklookViewController.view)
            self.containerView.addConstraints(self.fullscreenConstraints(for: self.quicklookViewController.view))

            if self.pickerDelegate != nil {
                self.navigationController?.setToolbarHidden(false, animated: true)
            } else {
                let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(sharePressed(_:)))
                self.navigationItem.setRightBarButton(shareButton, animated: true)
            }
        }
    }

    @objc private func sharePressed(_ sender: Any) {
        guard let URL = self.quicklookViewController.currentPreviewItem?.previewItemURL,
            let data = try? Data(contentsOf: URL) ,
            let image = UIImage(data: data) else { return }

        let shareController = UIActivityViewController(activityItems: [image as Any], applicationActivities: nil)
        shareController.excludedActivityTypes = [.postToFacebook, .postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToTencentWeibo]
        self.present(shareController, animated: true)
    }
}

extension FilePreviewViewController: QLPreviewControllerDataSource {
    private class FilePreviewItem: NSObject, QLPreviewItem {
        let previewItemTitle: String?
        let previewItemURL: URL?

        init(name: String?, url: URL?) {
            self.previewItemURL = url
            self.previewItemTitle = name
            super.init()
        }
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.item == nil ? 0 : 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return FilePreviewItem(name: self.item?.name, url: self.item?.localURL)
    }
}
