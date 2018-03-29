//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class NewsDetailViewController: UIViewController {

    var newsArticle: NewsArticle!

    @IBOutlet var newsTitle: UILabel!
    @IBOutlet var displayAt: UILabel!
    @IBOutlet var content: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsTitle.text = self.newsArticle.title
        self.displayAt.text = NewsArticle.displayDateFormatter.string(from: self.newsArticle.displayAt)
        self.content.attributedText = self.newsArticle.content.convertedHTML
        self.content.textContainerInset = .zero
        self.content.textContainer.lineFragmentPadding = 0
    }

}
