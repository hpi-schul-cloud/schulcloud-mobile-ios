//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class HomeworkOverviewCell: UITableViewCell {
    @IBOutlet private weak var colorView: UIView!
    @IBOutlet private weak var lessonName: UILabel!
    @IBOutlet private weak var homeworkDueCount: UILabel!

    func configure(course: Course, homeworkCount: Int) {
        self.colorView.layer.cornerRadius = self.colorView.bounds.width / 2.0
        colorView.backgroundColor = UIColor(hexString: course.colorString!)
        lessonName.text = course.name
        homeworkDueCount.text = "\(homeworkCount)"
    }
}
