//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class HomeworkByCourseCell: UITableViewCell {

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var dueDate: UILabel!
    @IBOutlet private weak var descriptionText: UILabel!

    func configure(for homework: Homework) {
        self.title.text = homework.name
        self.dueDate.text = Homework.dateTimeFormatter.string(from: homework.dueDate)

        var homeworkDescription = homework.cleanedDescriptionText
        if let attributedHTML = homeworkDescription.convertedHTML {
            let attributedString = NSMutableAttributedString(attributedString: attributedHTML)
            let range = NSRange(location: 0, length: attributedString.string.count)
            attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: range)
            homeworkDescription = attributedString.trimmedAttributedString(set: .whitespacesAndNewlines).string
        }

        self.descriptionText.text = homeworkDescription
    }
}
