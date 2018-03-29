//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit
import WebKit

/// TODO(permissions):
///     contentView? Should we not display the content of lesson if no permission? Seems off
class SingleLessonViewController: UIViewController, WKUIDelegate {
    
    var lesson: Lesson!
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userContentController = WKUserContentController()
        let cookieScriptSource = "document.cookie = 'jwt=\(Globals.account!.accessToken!)'"
        let cookieScript = WKUserScript(source: cookieScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(cookieScript)
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userContentController
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self

        self.view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        let guide = self.view.readableContentGuide
        guide.leadingAnchor.constraint(equalTo: webView.leadingAnchor).isActive = true
        guide.trailingAnchor.constraint(equalTo: webView.trailingAnchor).isActive = true

        self.title = lesson.name

        self.loadContents(lesson.contents)
    }

    func loadContents(_ contents: Set<LessonContent>) {
        let rendered = contents.map(htmlForElement)
        let concatenated = "<html><head>\(Constants.textStyleHtml)<meta name=\"viewport\" content=\"initial-scale=1.0\"></head>" + rendered.joined(separator: "<hr>") + "</body></html>"
        webView.loadHTMLString(concatenated, baseURL: Constants.Servers.web.url)
    }
    
    func htmlForElement(_ content: LessonContent) -> String {
        switch(content.type) {
        case .text:
            var rendered = ""
            if let title = content.title, !title.isEmpty {
                rendered += "<h1>\(title)</h1>"
            }
            rendered += content.text ?? ""
            return rendered
        case .other:
            return "<span class=\"not-supported\">Dieser Typ wird leider noch nicht unterstützt.</span>"
        }
    }
    
}
