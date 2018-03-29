//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
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
