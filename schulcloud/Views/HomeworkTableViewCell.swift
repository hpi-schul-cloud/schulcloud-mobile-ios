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

        self.coloredStrip.layer.cornerRadius = self.coloredStrip.frame.size.height/2
        self.coloredStrip.layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.coloredStrip.layer.cornerRadius = self.coloredStrip.frame.size.height/2.0
    }

    func configure(for homework: Homework) {
        self.subjectLabel.text = homework.courseName.uppercased()
        self.titleLabel.text = homework.name
        self.coloredStrip.backgroundColor = homework.color

        let description = homework.cleanedDescriptionText
        if let attributedString = NSMutableAttributedString(html: description) {
            let range = NSMakeRange(0, attributedString.string.count)
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .body), range: range)
            self.contentLabel.text = attributedString.trailingNewlineChopped.string
        } else {
            self.contentLabel.text = description
        }

        let (dueText, dueColor) = homework.dueTextAndColor
        self.dueLabel.text = dueText
        self.dueLabel.textColor = dueColor
    }

}
