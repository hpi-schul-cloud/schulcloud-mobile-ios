//
//  PreviewManager.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 16/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//
//
//    The MIT License (MIT)
//
//    Copyright (c) 2016 Roy Marmelstein
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
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
        
        switch(self.file.path.pathExtension) {
        case "plist", "json", "txt":
            let webviewPreviewViewContoller = WebviewPreviewViewContoller(nibName: "WebviewPreviewViewContoller", bundle: Bundle(for: WebviewPreviewViewContoller.self))
            webviewPreviewViewContoller.fileData = self.fileData
            webviewPreviewViewContoller.file = self.file
            return webviewPreviewViewContoller
        default:
            let previewTransitionViewController = PreviewTransitionViewController(nibName: "PreviewTransitionViewController", bundle: Bundle(for: PreviewTransitionViewController.self))
            previewTransitionViewController.quickLookPreviewController.dataSource = self
            return previewTransitionViewController
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
        let fileExtension = file.path.pathExtension
        let targetURL = tempDirectoryURL.appendingPathComponent("\(file.displayName).\(fileExtension)")  // TODO: better file extensions
        
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
    
    public var previewItemURL: URL?
    
}
