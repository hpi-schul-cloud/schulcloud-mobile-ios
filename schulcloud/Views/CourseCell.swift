//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class CourseCell: UICollectionViewCell {
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var teacherLabel: UILabel!
    
    func configure(for course: Course) {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4.0
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor(white: 0.7, alpha: 1.0).cgColor

        self.titleLabel.text = course.name
        if course.teachers.isEmpty {
            self.teacherLabel.isHidden = true
        } else {
            let namesAbbreviated = course.teachers.map { $0.shortName }
            self.teacherLabel.text = namesAbbreviated.joined(separator: ", ")
            self.teacherLabel.isHidden = false
        }
        
        if let color = course.colorString {
            self.colorView.backgroundColor = UIColor(hexString: color)
        }
    }
}
