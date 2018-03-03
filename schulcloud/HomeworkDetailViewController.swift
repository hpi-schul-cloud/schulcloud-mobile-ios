//
//  HomeworkDetailViewController.swift
//  schulcloud
//
//  Created by Max Bothe on 04.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class HomeworkDetailViewController: UIViewController {

    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var coloredStrip: UIView!
    @IBOutlet weak var dueLabel: UILabel!
    @IBOutlet weak var submissionButton: UIButton!
    
    var homework: Homework?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.coloredStrip.layer.cornerRadius = self.coloredStrip.frame.size.height/2.0

        guard let homework = self.homework else { return }
        self.configure(for: homework)
    }

    func configure(for homework: Homework) {
        self.subjectLabel.text = homework.courseName.uppercased()
        self.titleLabel.text = homework.name
        self.coloredStrip.backgroundColor = homework.color

        let description = homework.cleanedDescriptionText
        if let attributedString = NSMutableAttributedString(html: description) {
            let range = NSMakeRange(0, attributedString.string.count)
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .body), range: range)
            self.contentLabel.attributedText = attributedString.trailingNewlineChopped
        } else {
            self.contentLabel.text = description
        }

        let (dueText, dueColor) = homework.dueTextAndColor
        self.dueLabel.text = dueText
        self.dueLabel.textColor = dueColor
        
        if true /* check if homework is eligible for submissions */ {
            submissionButton.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segue.identifier) {
        case "taskSubmission"?:
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first! as! HomeworkSubmissionViewController
            destination.homework = self.homework!
        default:
            break
        }
    }

}
