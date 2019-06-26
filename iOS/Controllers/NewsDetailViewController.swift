//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class NewsDetailViewController: UIViewController {

    var newsArticle: NewsArticle!

    @IBOutlet private var newsTitle: UILabel!
    @IBOutlet private var displayAt: UILabel!
    @IBOutlet private var content: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsTitle.text = self.newsArticle.title
        self.displayAt.text = NewsArticle.displayDateFormatter.string(from: self.newsArticle.displayAt)
        self.content.attributedText = HTMLHelper.default.attributedString(for: self.newsArticle.content).value
        self.content.textContainerInset = .zero
        self.content.textContainer.lineFragmentPadding = 0
    }

}
