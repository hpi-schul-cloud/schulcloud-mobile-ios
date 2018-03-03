//
//  News+CoreDataProperties.swift
//  
//
//  Created by Florian Morel on 03.01.18.
//
//

import Foundation
import CoreData


extension NewsArticle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsArticle> {
        return NSFetchRequest<NewsArticle>(entityName: "NewsArticle")
    }

    @NSManaged public var content: String
    @NSManaged public var createdAt: NSDate
    @NSManaged public var displayAt: NSDate
    @NSManaged public var history: [String]
    @NSManaged public var id: String
    @NSManaged public var schoolId: String?
    @NSManaged public var title: String
    @NSManaged public var updatedAt: NSDate?
    @NSManaged public var creator: User?
}
