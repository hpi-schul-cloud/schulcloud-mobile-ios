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
    
    @IBOutlet var dueLabel: UILabel!
    @IBOutlet var contentLabelDueAlertSpacing: NSLayoutConstraint!
    
    func configure(for homework: Homework) {
        subjectLabel.text = homework.course?.name.uppercased() ?? "PERSÖNLICH"
        titleLabel.text = homework.name
//        coloredStrip.backgroundColor = homework.subject.color
        
        contentLabel.numberOfLines = 5
        
        let descriptionWithEndTrimmed = homework.descriptionText.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        if let attributedString = NSMutableAttributedString(html: descriptionWithEndTrimmed) {
            contentLabel.attributedText = attributedString.trailingNewlineChopped
        } else {
            contentLabel.text = homework.descriptionText
        }
        
        setDueLabelVisible(true)
        
        let timeDifference = Calendar.current.dateComponents([.day, .hour], from: Date(), to: homework.dueDate as Date)
        switch timeDifference.day! {
        case Int.min..<0:
            dueLabel.text = "⚐ Überfällig"
            setDueLabelHighlighted(true)
        case 0..<1:
            dueLabel.text = "⚐ In \(timeDifference.hour!) Stunden fällig"
            setDueLabelHighlighted(true)
        case 1:
            dueLabel.text = "⚐ Morgen fällig"
            setDueLabelHighlighted(true)
        case 2:
            dueLabel.text = "Übermorgen"
            setDueLabelHighlighted(false)
        case 3...7:
            dueLabel.text = "In \(timeDifference.day!) Tagen"
            setDueLabelHighlighted(false)
        default:
            setDueLabelVisible(false)
        }
    }
    
    func setDueLabelHighlighted(_ highlighted: Bool) {
        dueLabel.textColor = highlighted ? UIColor(red: 1.0, green: 45/255, blue: 0.0, alpha: 1.0) : UIColor.black
        if highlighted {
//            dueLabel.layer.borderColor = dueLabel.highlightedTextColor?.cgColor
//            dueLabel.layer.borderWidth = 1.0
        } else {
            dueLabel.layer.borderWidth = 0.0
        }
    }
    
    func setDueLabelVisible(_ visible: Bool) {
        dueLabel.isHidden = !visible
        contentLabelDueAlertSpacing.priority = visible ? 750 : 1
    }
}
