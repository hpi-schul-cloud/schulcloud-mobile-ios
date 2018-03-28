//
//  NewsCell.swift
//  schulcloud
//
//  Created by Florian Morel on 04.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class NewsArticleCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var timeSinceCreated: UILabel!
    @IBOutlet weak var content: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.content.textContainerInset = .zero
        self.content.textContainer.lineFragmentPadding = 0
    }

    func configure(for newsArticle: NewsArticle) {
        self.title.text = newsArticle.title
        self.timeSinceCreated.text = NewsArticle.displayDateFormatter.string(for: newsArticle.displayAt)
        self.content.attributedText = newsArticle.content.convertedHTML
        self.content.translatesAutoresizingMaskIntoConstraints = true
        self.content.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        self.content.sizeToFit()
    }

}
