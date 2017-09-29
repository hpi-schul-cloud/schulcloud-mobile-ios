//
//  HomeworkComment+CoreDataProperties.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 28.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//
//

import Foundation
import CoreData


extension HomeworkComment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HomeworkComment> {
        return NSFetchRequest<HomeworkComment>(entityName: "HomeworkComment")
    }

    @NSManaged public var submission: HomeworkSubmission

}
