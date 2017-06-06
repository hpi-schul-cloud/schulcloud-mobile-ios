//
//  CourseCell.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 05.06.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class CourseCell: UICollectionViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    
    func configure(for course: Course) {
        titleLabel.text = course.name
        if let color = course.colorString {
            backgroundColor = UIColor(hexString: color)
        }
    }
}
