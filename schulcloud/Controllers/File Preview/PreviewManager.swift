//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import QuickLook

class PreviewManager: NSObject, QLPreviewControllerDataSource {

    let file: File
    let fileData: Data

    init(file: File, data: Data) {
        self.file = file
        self.fileData = data
    }

    lazy var previewViewController: UIViewController = {

        switch(self.file.url.pathExtension) {
        case "plist", "json", "txt":
            let webviewPreviewViewContoller = WebviewPreviewViewContoller(nibName: "WebviewPreviewViewContoller", bundle: Bundle(for: WebviewPreviewViewContoller.self))
            webviewPreviewViewContoller.fileData = self.fileData
            webviewPreviewViewContoller.file = self.file
            return webviewPreviewViewContoller
        default:
            let quickLookPreviewController = QLPreviewController()
            quickLookPreviewController.dataSource = self
            quickLookPreviewController.title = self.file.name
            return quickLookPreviewController
        }
    }()

    // MARK: delegate methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let item = PreviewItem()

        if let url = file.cacheUrl ?? copyDataToTemporaryDirectory(fileData, file: file) {
            item.previewItemURL = url
        }

        return item
    }

    func copyDataToTemporaryDirectory(_ data: Data, file: File) -> URL?
    {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        let fileExtension = file.url.pathExtension
        let targetURL = tempDirectoryURL.appendingPathComponent("\(file.name).\(fileExtension)")  // TODO: better file extensions

        // Copy the file.
        do {
            try data.write(to: targetURL)
            return targetURL
        } catch let error {
            log.error("Unable to copy file: \(error)")
            return nil
        }
    }
}

class PreviewItem: NSObject, QLPreviewItem {

    /*!
     * @abstract The URL of the item to preview.
     * @discussion The URL must be a file URL.
     */

    var previewItemURL: URL?

}
