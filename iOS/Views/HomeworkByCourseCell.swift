//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class HomeworkByCourseCell: UITableViewCell {

    static var formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .short
        return dateFormatter
    }()

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var dueDate: UILabel!
    @IBOutlet private weak var descriptionText: UILabel!

    func configure(with homework: Homework) {

        title?.text = homework.name
        dueDate?.text = "\(HomeworkByCourseCell.formatter.string(from: homework.dueDate))"

        var homeworkDescription = homework.cleanedDescriptionText
        if let attributedString = NSMutableAttributedString(html: homeworkDescription) {
            let range = NSRange(location: 0, length: attributedString.string.count)
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .body), range: range)
            homeworkDescription = attributedString.trailingNewlineChopped.string
        }

        descriptionText.text = homeworkDescription
    }
}
