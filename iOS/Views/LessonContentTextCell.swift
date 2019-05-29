//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class LessonContentTextCell: UITableViewCell {

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.textView.textContainerInset = .zero
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.translatesAutoresizingMaskIntoConstraints = false
    }

    func configure(title: String, text: NSAttributedString) {
        self.title.text = title
        self.textView.attributedText = text
        self.textView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        self.textView.sizeToFit()
    }
}
