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
        let createdAt: Date
        
        var timeSinceCreated: String {
            let component = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: createdAt, to: Date())
            
            if let year = component.year,
                year > 0 {
                
               return "\(year) years ago"
            } else if let month = component.month,
                month > 0 {
                
               return "\(month) months ago"
            } else if let day = component.day,
                day > 0 {
                
               return "\(day) days ago"
            } else if let hour = component.hour,
                hour > 0 {
                
               return "\(hour) hours ago"
            } else if let minute = component.minute,
                minute > 0 {
                
               return "\(minute) minutes ago"
            } else if let second = component.second,
                second > 0 {
                
               return "\(second) seconds ago"
            }
            
            return ""
        }
    }
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var timeSinceCreated: UILabel!
    @IBOutlet weak var content: UIWebView!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
}
