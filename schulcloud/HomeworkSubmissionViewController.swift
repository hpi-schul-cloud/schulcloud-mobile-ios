//
//  HomeworkSubmissionViewController.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 14.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

class HomeworkSubmissionViewController: UIViewController {

    var homework: Homework!
    var homeworkSubmission: HomeworkSubmission?
    
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        // TODO: save data temporally?
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        do {
            guard let text = textView.attributedText else {
                return
            }
            let documentAttributes = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType]
            let htmlData = try text.data(from: NSMakeRange(0, text.length), documentAttributes: documentAttributes)
            if let htmlString = String(data: htmlData, encoding: .utf8) {
               
            } else {
                log.error("Could not encode string")
            }
        }
        catch let error {
            log.error("error creating HTML from Attributed String: \(error.description)")
        }
    }
    

}
