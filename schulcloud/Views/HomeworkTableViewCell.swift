//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class HomeworkTableViewCell: UITableViewCell {

    @IBOutlet private var subjectLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var contentLabel: UILabel!
    @IBOutlet private var coloredStrip: UIView!
    @IBOutlet private var dueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.coloredStrip.layer.cornerRadius = self.coloredStrip.frame.size.height / 2.0
        self.coloredStrip.layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.coloredStrip.layer.cornerRadius = self.coloredStrip.frame.size.height / 2.0
    }

    func configure(for homework: Homework) {
        self.subjectLabel.text = homework.courseName.uppercased()
        self.titleLabel.text = homework.name
        self.coloredStrip.backgroundColor = homework.color

        let homeworkDescription = homework.cleanedDescriptionText
        var renderedString = cachedDescriptionString[homework.id]
        if renderedString == nil {
            if let attributedString = NSMutableAttributedString(html: homeworkDescription) {
                let range = NSRange(location: 0, length: attributedString.string.count)
                attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .body), range: range)
                renderedString = attributedString.trailingNewlineChopped.string
            } else {
                renderedString = homeworkDescription
            }
            cachedDescriptionString[homework.id] = renderedString
        }
        self.contentLabel.text = renderedString

        let (dueText, dueColor) = homework.dueTextAndColor
        self.dueLabel.text = dueText
        self.dueLabel.textColor = dueColor
    }

}
