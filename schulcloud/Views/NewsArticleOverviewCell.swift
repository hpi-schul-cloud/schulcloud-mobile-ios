//
//  NewsArticleOverviewCell.swift
//  schulcloud
//
//  Created by Max Bothe on 27.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class NewsArticleOverviewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var timeSinceCreated: UILabel!
    @IBOutlet weak var content: UILabel!

    func configure(for newsArticle: NewsArticle) {
        self.title.text = newsArticle.title
        self.timeSinceCreated.text = NewsArticle.displayDateFormatter.string(for: newsArticle.displayAt)
        self.content.text = newsArticle.content.convertedHTML?.string.replacingOccurrences(of: "\n", with: " ")
    }

}
