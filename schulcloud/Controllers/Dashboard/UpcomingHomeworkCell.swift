//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

var cachedDescriptionString = [String: String]()

final class UpcomingHomeworkCell: UITableViewCell {

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
        dueDate?.text = "\(UpcomingHomeworkCell.formatter.string(from: homework.dueDate))"

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
        descriptionText.text = renderedString
    }
}
