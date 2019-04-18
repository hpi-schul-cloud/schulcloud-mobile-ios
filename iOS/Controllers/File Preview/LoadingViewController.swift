//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import Common
import Foundation
import QuickLook

protocol LoadingViewControllerDelegate: AnyObject {
    func controllerDidFinishLoading(error: SCError?)
}

class LoadingViewController: UIViewController {
    // MARK: Lifecycle

    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var errorLabel: UILabel!
    @IBOutlet private var cancelButton: UIButton!

    let fileSync = FileSync.default
    var file: File!
    weak var delegate: LoadingViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        progressView.setProgress(0, animated: false)
        if self.delegate != nil {
            cancelButton.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startDownload()
    }

    @IBAction private func cancelButtonTapped(_ sender: Any) {
        self.progressView.observedProgress?.cancel()
        navigationController?.popViewController(animated: true)
    }

    func startDownload() {
        // Count 4, 1/4 is download of signedURL, 3/4 download of the file itself.
        // This gives more importance to the file download in term of progress
        let progress = Progress(totalUnitCount: 4)
        progress.isCancellable = true
        progress.cancellationHandler = { }

        let localURL = self.file.localURL
        guard !FileManager.default.fileExists(atPath: localURL.path) else {
            progress.becomeCurrent(withPendingUnitCount: 0)
            self.delegate?.controllerDidFinishLoading(error: nil)
            return
        }

        let fileID = self.file.id
        let itemIdentifier = NSFileProviderItemIdentifier(fileID)
        let signedURLTask = self.fileSync.downloadSignedURL(fileId: fileID) { [weak self] result in
            if #available(iOS 11.0, *) {
            } else {
                progress.becomeCurrent(withPendingUnitCount: 3)
            }

            guard let signedURL = result.value else {
                progress.becomeCurrent(withPendingUnitCount: 0)
                DispatchQueue.main.async {
                    self?.delegate?.controllerDidFinishLoading(error: result.error)
                }

                return
            }

            let tasko = self?.fileSync.download(id: "filedownload__\(fileID)",
                                                at: signedURL,
                                                moveTo: localURL,
                                                backgroundSession: false) { [weak self] result in
                if #available(iOS 11.0, *) {
                } else {
                    progress.becomeCurrent(withPendingUnitCount: 0)
                }

                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self?.delegate?.controllerDidFinishLoading(error: nil)
                    }

                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.delegate?.controllerDidFinishLoading(error: error)
                    }
                }
            }

            guard let task = tasko else {
                progress.becomeCurrent(withPendingUnitCount: 0)
                return
            }

            if #available(iOS 11.0, *) {
                NSFileProviderManager.default.register(task, forItemWithIdentifier: itemIdentifier) { _ in }
                progress.addChild(task.progress, withPendingUnitCount: 3)
            }

            task.resume()
        }

        if #available(iOS 11.0, *) {
            progress.addChild(signedURLTask!.progress, withPendingUnitCount: 1)
        }

        signedURLTask?.resume()
        self.progressView.observedProgress = progress
    }
}
