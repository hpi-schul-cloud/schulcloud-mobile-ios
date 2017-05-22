//
//  WebviewPreviewViewContoller.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 16/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
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
import WebKit

/// Webview for rendering items QuickLook will struggle with.
class WebviewPreviewViewContoller: UIViewController {
    
    var webView = WKWebView()

    var file: File? {
        didSet {
            self.title = file?.displayName
            self.processForDisplay()
        }
    }
    
    var fileData: Data?

    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(webView)
        
        // Add share button
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(WebviewPreviewViewContoller.shareFile))
        self.navigationItem.rightBarButtonItem = shareButton
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        webView.frame = self.view.bounds
    }
    
    //MARK: Share
    
    func shareFile() {
        guard let file = file else {
            return
        }
        
        let activityItems: [Any]
        if let data = fileData {
            activityItems = [data]
        } else if let url = file.cacheUrl {
            activityItems = [url]
        } else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)

    }

    //MARK: Processing
    
    func processForDisplay() {
        guard let file = file else {
            print("file is not set!")
            return
        }
        
        let data: Data
        if let fileData = fileData {
            data = fileData
        } else if let localFileUrl = file.cacheUrl,
            localFileUrl.scheme == "file",
            let fileData = try? Data(contentsOf: localFileUrl) {
            data = fileData
        } else {
            print("Could not find data for file!")
            return
        }
        
        var rawString: String?
        
        // Prepare plist for display
        if file.path.pathExtension.lowercased() == "plist" {
            do {
                if let plistDescription = try (PropertyListSerialization.propertyList(from: data, options: [], format: nil) as AnyObject).description {
                    rawString = plistDescription
                }
            } catch {}
        }
        
        // Prepare json file for display
        else if file.path.pathExtension.lowercased() == "json" {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if JSONSerialization.isValidJSONObject(jsonObject) {
                    let prettyJSON = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    var jsonString = String(data: prettyJSON, encoding: String.Encoding.utf8)
                    // Unescape forward slashes
                    jsonString = jsonString?.replacingOccurrences(of: "\\/", with: "/")
                    rawString = jsonString
                }
            } catch {}
        }
        
        // Default prepare for display
        if rawString == nil {
            rawString = String(data: data, encoding: String.Encoding.utf8)
        }
        
        // Convert and display string
        if let convertedString = convertSpecialCharacters(rawString) {
            let htmlString = "<html><head><meta name='viewport' content='initial-scale=1.0, user-scalable=no'></head><body><pre>\(convertedString)</pre></body></html>"
            webView.loadHTMLString(htmlString, baseURL: nil)
        }
        
    }
    

    // Make sure we convert HTML special characters
    // Code from https://gist.github.com/mikesteele/70ae98d04fdc35cb1d5f
    func convertSpecialCharacters(_ string: String?) -> String? {
        guard let string = string else {
            return nil
        }
        var newString = string
        let char_dictionary = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'"
        ];
        for (escaped_char, unescaped_char) in char_dictionary {
            newString = newString.replacingOccurrences(of: escaped_char, with: unescaped_char, options: NSString.CompareOptions.regularExpression, range: nil)
        }
        return newString
    }
}
