//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class UpcomingHomeworkCell: UITableViewCell {

    static var formatter: DateComponentsFormatter = {
        let componentFormatter = DateComponentsFormatter()
        componentFormatter.unitsStyle = .abbreviated
        return componentFormatter
    }()

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var dueDate: UILabel!
    @IBOutlet private weak var descriptionText: UILabel!

    func configure(with homework: Homework) {
        title?.text = homework.name
        dueDate?.text = "\(UpcomingHomeworkCell.formatter.string(from: Date(), to: homework.dueDate)!) left"
        let description = homework.cleanedDescriptionText
        if let attributedString = NSMutableAttributedString(html: description) {
            let range = NSRange(location: 0, length: attributedString.string.count)
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .body), range: range)
            descriptionText.text = attributedString.trailingNewlineChopped.string
        } else {
            descriptionText.text = description
        }
    }
}
