//
//  CourseCell.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 05.06.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
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
        if let teachers = course.teachers?.allObjects as? [User], teachers.count > 0 {
            self.teacherLabel.isHidden = false
            let namesAbbreviated = teachers.map {"\($0.firstName[$0.firstName.startIndex]). \($0.lastName)"}
            self.teacherLabel.text = namesAbbreviated.joined(separator: ", ")
        } else {
            self.teacherLabel.isHidden = true
        }
        
        if let color = course.colorString {
            self.colorView.backgroundColor = UIColor(hexString: color)
        }
    }
}
