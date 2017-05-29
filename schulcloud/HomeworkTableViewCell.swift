//
//  HomeworkTableViewCell.swift
//  schulcloud
//
//  Created by Carl Gödecken on 29.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class HomeworkTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.clear
    }

    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var coloredStrip: UIView!
    
    func configure(for homework: Homework) {
        subjectLabel.text = homework.courseId?.uppercased()
        titleLabel.text = homework.name
//        coloredStrip.backgroundColor = homework.subject.color
        let descriptionWithEndTrimmed = homework.descriptionText.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        if let attributedString = NSMutableAttributedString(html: descriptionWithEndTrimmed) {
            
            contentLabel.attributedText = attributedString.trailingNewlineChopped
        } else {
            contentLabel.text = homework.descriptionText
        }
    }
}
