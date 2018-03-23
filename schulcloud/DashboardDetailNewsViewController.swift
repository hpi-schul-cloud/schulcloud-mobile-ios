//
//  DashboardDetailNewsViewController.swift
//  schulcloud
//
//  Created by Florian Morel on 23.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

final class DashboardDetailNewsViewController : UIViewController {

    var newsArticle : NewsArticle!

    @IBOutlet var newsTitle: UILabel!
    @IBOutlet var displayAt: UILabel!
    @IBOutlet var content: UITextView!


    override func viewDidLoad() {
        super.viewDidLoad()
        newsTitle.text = newsArticle.title
        displayAt.text = NewsArticle.displayDateFormatter.string(from: newsArticle.displayAt)
        content.attributedText = newsArticle.content.convertedHTML
    }
}
