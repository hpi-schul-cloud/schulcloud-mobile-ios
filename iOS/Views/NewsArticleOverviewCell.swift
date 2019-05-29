//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

class NewsArticleOverviewCell: UITableViewCell {

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var timeSinceCreated: UILabel!
    @IBOutlet private weak var content: UILabel!

    func configure(for newsArticle: NewsArticle) {
        self.title.text = newsArticle.title
        self.timeSinceCreated.text = NewsArticle.displayDateFormatter.string(for: newsArticle.displayAt)
        self.content.text = HTMLHelper.default.stringContent(of: newsArticle.content).value
    }
}
