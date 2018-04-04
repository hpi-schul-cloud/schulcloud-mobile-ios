//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

final class HomeworkOverviewCell : UITableViewCell {
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var lessonName: UILabel!
    @IBOutlet weak var homeworkDueCount: UILabel!

    func configure(course: Course, homeworkCount: Int) {
        self.colorView.layer.cornerRadius = self.colorView.bounds.width / 2.0
        colorView.backgroundColor = UIColor(hexString: course.colorString!)
        lessonName.text = course.name
        homeworkDueCount.text = "\(homeworkCount)"
    }
}
