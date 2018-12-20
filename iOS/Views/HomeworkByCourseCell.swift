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

        self.descriptionText.text = HTMLHelper.default.stringContent(of: homework.descriptionText)
    }
}
