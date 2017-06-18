//
//  SingleLessonViewController.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 17.06.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

class SingleLessonViewController: UITableViewController {
    
    var lesson: Lesson!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        self.title = lesson.name
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.hidesBarsOnSwipe = true
        navigationController?.hidesBarsOnTap = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnSwipe = false
        navigationController?.hidesBarsOnTap = false
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lesson.contents?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = lesson.contents![indexPath.row] as! Content
        switch(content.type) {
        case .text:
            let cell = tableView.dequeueReusableCell(withIdentifier: "html", for: indexPath) as! HtmlTableViewCell
            cell.setContent(content, inTableView: tableView)
            return cell
        case .other:
            log.debug("Unsupported content type \(content.component ?? "nil")")
            let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
            return cell
        }
    }
    
}
