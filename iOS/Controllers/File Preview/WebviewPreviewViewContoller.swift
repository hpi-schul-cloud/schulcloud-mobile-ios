//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit
import WebKit

// Webview for rendering items QuickLook will struggle with.
class WebviewPreviewViewContoller: UIViewController {

    var webView = WKWebView()

    var file: File? {
        didSet {
            self.title = file?.name
            self.processForDisplay()
        }
    }

    var fileData: Data?

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(webView)

        if #available(iOS 11, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        // Add share button
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(WebviewPreviewViewContoller.shareFile))
        self.navigationItem.rightBarButtonItem = shareButton
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        webView.frame = self.view.bounds
    }

    // MARK: Share

    @objc func shareFile() {
        guard let file = self.file else {
            return
        }

        let activityItems: [Any]
        if let data = self.fileData {
            activityItems = [data]
        } else if file.downloadState == .downloaded {
            activityItems = [file.localURL]
        } else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)

    }

    // MARK: Processing

    func processForDisplay() {
        guard let file = self.file else {
            print("file is not set!")
            return
        }

        let data: Data
        if let fileData = self.fileData {
            data = fileData
        } else if file.downloadState == .downloaded,
            let fileData = try? Data(contentsOf: file.localURL) {
            data = fileData
        } else {
            print("Could not find data for file!")
            return
        }

        var rawString: String?

        // Prepare plist for display
        if file.localURL.pathExtension.lowercased() == "plist" {
            do {
                if let plistDescription = try (PropertyListSerialization.propertyList(from: data, options: [], format: nil) as AnyObject).description {
                    rawString = plistDescription
                }
            } catch {}
        }

        // Prepare json file for display
        else if file.localURL.pathExtension.lowercased() == "json" {
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
            let htmlString = """
            <html>
            <head><meta name='viewport' content='initial-scale=1.0, user-scalable=no'></head>
            <body><pre>\(convertedString)</pre></body>
            </html>
            """
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
        let charMapping = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
        ]

        for (escapedChar, unescapedChar) in charMapping {
            newString = newString.replacingOccurrences(of: escapedChar, with: unescapedChar, options: NSString.CompareOptions.regularExpression, range: nil)
        }

        return newString
    }
}
