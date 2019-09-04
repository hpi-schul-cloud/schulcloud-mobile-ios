//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

class CourseCell: UICollectionViewCell {

    @IBOutlet private weak var colorView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var teacherLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 6.0
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor(white: 0.7, alpha: 1.0).cgColor
    }

    func configure(for course: Course) {
        self.titleLabel.text = course.name

        if course.teachers.isEmpty {
            self.teacherLabel.isHidden = true
        } else {
            let names = course.teachers.map { $0.shortName }
            self.teacherLabel.text = names.joined(separator: ", ")
            self.teacherLabel.isHidden = false
        }

        let courseColor = course.colorString.flatMap { UIColor(hexString: $0) }
        self.colorView.backgroundColor = courseColor ?? .white
    }
}

extension CourseCell {

    // swiftlint:disable:next cyclomatic_complexity
    static func minimalWidth(for contentSizeCategory: UIContentSizeCategory) -> CGFloat {
        switch contentSizeCategory {
        case .extraSmall:
            return 100
        case .small:
            return 110
        case .medium:
            return 120
        case .large:
            return 130
        case .extraLarge:
            return 140
        case .extraExtraLarge:
            return 150
        case .extraExtraExtraLarge:
            return 160

        case .accessibilityMedium:
            return 200
        case .accessibilityLarge:
            return 230
        case .accessibilityExtraLarge:
            return 260
        case .accessibilityExtraExtraLarge:
            return 290
        case .accessibilityExtraExtraExtraLarge:
            return 320

        default:
            return 200
        }
    }
}
