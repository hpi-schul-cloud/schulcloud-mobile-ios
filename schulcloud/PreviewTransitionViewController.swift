//
//  PreviewTransitionViewController.swift
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


import UIKit
import QuickLook

/// Preview Transition View Controller was created because of a bug in QLPreviewController. It seems that QLPreviewController has issues being presented from a 3D touch peek-pop gesture and is produced an unbalanced presentation warning. By wrapping it in a container, we are solving this issue.
class PreviewTransitionViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    
    let quickLookPreviewController = QLPreviewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addChildViewController(quickLookPreviewController)
        containerView.addSubview(quickLookPreviewController.view)
        quickLookPreviewController.view.frame = containerView.bounds
        quickLookPreviewController.didMove(toParentViewController: self)
        
        // Add share button
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(PreviewTransitionViewController.shareFile))
        self.navigationItem.rightBarButtonItem = shareButton
    }
    //MARK: Share
    
    func shareFile() {

        let activityItems: [Any]
        activityItems = [quickLookPreviewController.currentPreviewItem?.previewItemURL]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
        
    }


}
