//
//  LoadingViewController.swift
//  FileBrowser
//
//  Created by Carl Julius Gödecken on 29/12/2016.
//  Copyright © 2016 Carl Julius Gödecken.
//
//
//    The MIT License (MIT)
//
//    Copyright (c) 2016 Carl Julius Gödecken
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


class LoadingViewController: UIViewController, URLSessionDownloadDelegate, URLSessionDataDelegate {
    //MARK: Lifecycle
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    
    var downloadTask: URLSessionDownloadTask?
    var session: URLSession!
    
    var file: File!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.setProgress(0, animated: false)
 
        downloadTask = session.downloadTask(with: file.path)
        downloadTask!.resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        downloadTask?.cancel()
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        downloadTask?.cancel()
        navigationController?.popViewController(animated: true)
    }
    
    func showFile(data: Data?) {
        let previewManager = PreviewManager()
        let controller = previewManager.previewViewControllerForFile(self.file, data: data, fromNavigation: true)
        DispatchQueue.main.async {
            if let nav = self.navigationController {
                // TODO: add as subview
                var viewControllers = nav.viewControllers
                viewControllers.removeLast(1)
                viewControllers.append(controller)
                nav.setViewControllers(viewControllers, animated: true)
            } else {
                self.present(controller, animated: true, completion: nil)
            }
            if let ql = (controller as? QLPreviewController) ?? (controller as? PreviewTransitionViewController)?.quickLookPreviewController {
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
        }
    }
    
    //MARK: URLSession

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            show(error: error)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            self.showFile(data: data)
        } catch let error {
            print(error)
            show(error: error)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten / totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressView.setProgress(progress, animated: true)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as? NSError)?.code != NSURLErrorCancelled {
            show(error: error)
        }
        session.finishTasksAndInvalidate()
    }
}

