//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

/// TODO: Cancel request when poping

import Alamofire
import Foundation
import QuickLook
import BrightFutures


class LoadingViewController: UIViewController  {
    //MARK: Lifecycle

    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    var downloadTask: URLSessionDownloadTask?

    let fileSync = FileSync()
    var file: File!

    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.setProgress(0, animated: false)
        startDownload()
    }

    override func viewWillDisappear(_ animated: Bool) {
        downloadTask?.cancel()
    }


    @IBAction func cancelButtonTapped(_ sender: Any) {
        downloadTask?.cancel()
        navigationController?.popViewController(animated: true)
    }

    func startDownload() {
        fileSync.signedURL(for: file)
        .flatMap { url -> Future<Data, SCError> in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.progressView.isHidden = false
            }

            let future = self.fileSync.download(url: url, progressHandler: { (progress) in
                DispatchQueue.main.async {
                    self.progressView.setProgress(progress, animated: true)
                }
            })

            return future
        }.onSuccess { (fileData) in
            DispatchQueue.main.async {
                self.showFile(data: fileData)
            }
        }.onFailure { (error) in
            DispatchQueue.main.async {
                self.show(error: error)
            }
        }
    }

    func showFile(data: Data) {
        let previewManager = PreviewManager(file: file, data: data)
        let controller = previewManager.previewViewController
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true

        DispatchQueue.main.async {
            if let nav = self.navigationController {
                // TODO: add as subview
                var viewControllers = nav.viewControllers
                viewControllers.removeLast(1)
                viewControllers.append(controller)
                nav.setViewControllers(viewControllers, animated: false)
            } else {
                self.present(controller, animated: false, completion: nil)
            }

            if let ql = controller as? QLPreviewController {
                // fix for dataSource magically disappearing because hey let's store it in a weak variable in QLPreviewController
                ql.dataSource = previewManager
                ql.reloadData()
            }
        }
    }

    func show(error: Error) {
        DispatchQueue.main.async {
            self.cancelButton.isHidden = true
            self.progressView.isHidden = true
            self.errorLabel.text = error.localizedDescription
            self.errorLabel.isHidden = false
            self.activityIndicator.stopAnimating()
        }
    }

}

