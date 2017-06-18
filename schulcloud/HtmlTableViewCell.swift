//
//  HtmlTableViewCell.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 18.06.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class HtmlTableViewCell: UITableViewCell, UIWebViewDelegate {
    
    @IBOutlet var webView: UIWebView!
    @IBOutlet var webViewHeight: NSLayoutConstraint!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet var titleBottomConstraint: NSLayoutConstraint!
    
    weak var tableView: UITableView?
    
    weak var oldContent: Content?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        webView.scrollView.isScrollEnabled = false
        webView.delegate = self
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setContent(_ content: Content, inTableView tableView: UITableView) {
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
