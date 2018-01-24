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

}
