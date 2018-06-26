//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

class HtmlTableViewCell: UITableViewCell, UIWebViewDelegate {

    @IBOutlet private var webView: UIWebView!
    @IBOutlet private var webViewHeight: NSLayoutConstraint!

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet private var titleBottomConstraint: NSLayoutConstraint!

    weak var tableView: UITableView?

    weak var oldContent: LessonContent?

    override func awakeFromNib() {
        super.awakeFromNib()

        webView.scrollView.isScrollEnabled = false
        webView.delegate = self

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setContent(_ content: LessonContent, inTableView tableView: UITableView) {
        if content == oldContent {
            return  // prevent endless loops triggered by table view reloads due to webviews completing loading
        }

        oldContent = content
        self.tableView = tableView

        if let title = content.title, !title.isEmpty {
            titleLabel.text = title
            titleIsHidden = false
        } else {
            titleIsHidden = true
        }

        let html = "<html><head>\(Constants.textStyleHtml)</head><body>\(content.text ?? "")</body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }

    var titleIsHidden: Bool = false {
        didSet {
            titleLabel.isHidden = titleIsHidden
            titleTopConstraint.isActive = !titleIsHidden
            titleBottomConstraint.isActive = !titleIsHidden
        }
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.frame.size.height = 1.0 // hack to get it work
        let properSize = webView.sizeThatFits(CGSize(width: 1, height: 1))
        webView.frame.size = properSize
        webViewHeight.constant = properSize.height

        tableView?.beginUpdates()
        tableView?.endUpdates()
    }

}