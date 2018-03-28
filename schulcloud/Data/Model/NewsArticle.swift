//
//  NewsArticle.swift
//  
//
//  Created by Florian Morel on 03.01.18.
//
//

import Foundation
import CoreData

final class NewsArticle: NSManagedObject {

    @NSManaged public var content: String
    @NSManaged public var displayAt: Date
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var updatedAt: Date?
    @NSManaged public var creator: User?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsArticle> {
        return NSFetchRequest<NewsArticle>(entityName: "NewsArticle")
    }

}

extension NewsArticle : Pullable {

    static var type: String {
        return "news"
    }

    func update(from object: ResourceData, with context: SynchronizationContext) throws {
        self.content = try object.value(for: "content")
        self.displayAt = try object.value(for: "displayAt")
        self.title = try object.value(for: "title")
        self.updatedAt = try object.value(for: "updatedAt")

        try self.updateRelationship(forKeyPath: \NewsArticle.creator, forKey: "creatorId", fromObject: object, with: context)
    }

    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
}
