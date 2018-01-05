//
//  NewsCell.swift
//  schulcloud
//
//  Created by Florian Morel on 04.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit


class NewsCell: UITableViewCell {
    
    //TODO: replace with the actual news
    public struct News {
        let title: String
        let content: String
        let createdAt: NSDate
    }
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var timeSinceCreated: UILabel!
    @IBOutlet weak var content: UIWebView!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
}
