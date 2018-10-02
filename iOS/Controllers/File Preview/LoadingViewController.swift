//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

/// TODO: Cancel request when poping

import BrightFutures
import Common
import Foundation
import QuickLook

class LoadingViewController: UIViewController {
    // MARK: Lifecycle

    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var errorLabel: UILabel!
    @IBOutlet private var cancelButton: UIButton!

    let fileSync = FileSync.default
    var file: File!

    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.setProgress(0, animated: false)
        startDownload()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func startDownload() {

        // Count 4, 1/4 is download of signedURL, 3/4 download of the file itself.
        // This gives more importance to the file download in term of progress
        let progress = Progress(totalUnitCount: 4)
        progress.isCancellable = true
        progress.cancellationHandler = { }
        let localURL = self.file.localURL

        let signedURLTask = self.fileSync.signedURL(for: self.file) { [weak self] signedURL, error in
            if #available(iOS 11.0, *) {
            }else {
                progress.becomeCurrent(withPendingUnitCount: 3)
            }

            guard let signedURL = signedURL else {
                progress.becomeCurrent(withPendingUnitCount: 0)
                DispatchQueue.main.async {
                    self?.show(error: error!)
                }
                return
            }
            let task = self?.fileSync.download(id: "filedownload__\(self!.file.id)", at: signedURL, moveTo: localURL, backgroundSession: false) { fileURL, error in
                if #available(iOS 11.0, *) {
                }else {
                    progress.becomeCurrent(withPendingUnitCount: 0)
                }
                guard let _ = fileURL else {
                    DispatchQueue.main.async {
                        self?.show(error: error!)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self?.showFile()
                }
            }
            if #available(iOS 11.0, *) {
                progress.addChild(task!.progress, withPendingUnitCount: 3)
            }
            task?.resume()
        }
        if #available(iOS 11.0, *) {
            progress.addChild(signedURLTask!.progress, withPendingUnitCount: 1)
        }
        signedURLTask?.resume()
        self.progressView.observedProgress = progress
    }

    func showFile() {

        let objectID = file.objectID
        let context = CoreDataHelper.persistentContainer.newBackgroundContext()
        context.performAndWait {
            let file = context.typedObject(with: objectID) as File
            file.lastReadAt = Date()

            guard let syncAnchor = context.fetchSingle(WorkingSetSyncAnchor.mainAnchorFetchRequest).value else {
                return
            }
            syncAnchor.value += 1

            _ = context.saveWithResult()
        }

        if #available(iOS 11.0, *) {
            NSFileProviderManager.default.signalEnumerator(for: NSFileProviderItemIdentifier(file.id)) { _ in }
            NSFileProviderManager.default.signalEnumerator(for: NSFileProviderItemIdentifier.workingSet) { error in
                if let error = error {
                    print("Error signaling to working set: \(error)")
                } else {
                    print("WorkingSet signaled")
                }
            }
        }

        let previewManager = PreviewManager(file: file)
        let controller = previewManager.previewViewController
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true

        if let nav = self.navigationController {
            // TODO: add as subview
            var viewControllers = nav.viewControllers
            viewControllers.removeLast(1)
            viewControllers.append(controller)
            nav.setViewControllers(viewControllers, animated: false)
        } else {
            self.present(controller, animated: false, completion: nil)
        }

        if let quickLook = controller as? QLPreviewController {
            // fix for dataSource magically disappearing because hey let's store it in a weak variable in QLPreviewController
            quickLook.dataSource = previewManager
            quickLook.reloadData()
        }
    }

    func show(error: Error) {
        self.cancelButton.isHidden = true
        self.progressView.isHidden = true
        self.errorLabel.text = error.localizedDescription
        self.errorLabel.isHidden = false
    }
}
