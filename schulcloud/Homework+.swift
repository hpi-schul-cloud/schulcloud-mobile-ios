//
//  Homework+.swift
//  schulcloud
//
//  Created by Max Bothe on 05.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

//import Foundation
//import BrightFutures
//import CoreData
//import Marshal
//
//extension Homework {
//
//    static let homeworkDidChangeNotificationName = "didChangeHomework"
//
//    static func upsert(inContext context: NSManagedObjectContext, object: MarshaledObject) -> Future<Homework, SCError> {
//        do {
//            let fetchRequest = NSFetchRequest<Homework>(entityName: "Homework")
//            let id: String = try object.value(for: "_id")
//            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
//
//            let result = try context.fetch(fetchRequest)
//            let homework = result.first ?? Homework(context: context)
//            if result.count > 1 {
//                throw SCError.database("Found more than one result for \(fetchRequest)")
//            }
//
//            homework.id = try object.value(for: "_id")
//            homework.name = try object.value(for: "name")
//            homework.descriptionText = try object.value(for: "description")
//            homework.availableDate = try object.value(for: "availableDate")
//            homework.dueDate = try object.value(for: "dueDate")
//            homework.publicSubmissions = (try? object.value(for: "publicSubmissions")) ?? false
//            homework.isPrivate = (try? object.value(for: "private")) ?? false
//
//            let courseId: String? = try? object.value(for: "courseId")
//            let teacherId: String = try object.value(for: "teacherId")
//
//            let homeworkFuture = homework.fetchCourse(by: courseId, context: context).onErrorLogAndRecover(with: Void())
//            let teacherFuture = homework.fetchTeacher(by: teacherId, context: context).onErrorLogAndRecover(with: Void())
//            
//            return [homeworkFuture, teacherFuture].sequence().flatMap(object: homework)
//        } catch let error as MarshalError {
//            return Future(error: .jsonDeserialization(error.description))
//        } catch let error {
//            return Future(error: .database(error.localizedDescription))
//        }
//    }
//    
//    func fetchCourse(by id: String?, context: NSManagedObjectContext) -> Future<Void, SCError> {
//        guard let id = id else { return Future(value: Void())}
//        return Course.fetchQueue.sync {
//            return Course.fetch(by: id, inContext: context).flatMap { course -> Future<Void, SCError> in
//                self.course = course
//                return Future(value: Void())
//            }
//        }
//    }
//    
//    func fetchTeacher(by id: String?, context: NSManagedObjectContext) -> Future<Void, SCError> {
//        guard let id = id else { return Future(value: Void())}
//        return User.fetchQueue.sync {
//            return User.fetch(by: id, inContext: context).flatMap { teacher -> Future<Void, SCError> in
//                self.teacher = teacher
//                return Future(value: Void())
//            }
//        }
//    }
//
//}


//extension Homework {
//
//    var courseName: String {
//        return self.course?.name ?? "Persönlich"
//    }
//
//    var color: UIColor {
//        if let colorString = self.course?.colorString {
//            return UIColor(hexString: colorString)!
//        } else {
//            return UIColor.clear
//        }
//    }
//
//    var cleanedDescriptionText: String {
//        return self.descriptionText.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
//    }
//
//    var dueTextAndColor: (String, UIColor) {
//        let highlightColor = UIColor(red: 1.0, green: 45/255, blue: 0.0, alpha: 1.0)
//        let timeDifference = Calendar.current.dateComponents([.day, .hour], from: Date(), to: self.dueDate as Date)
//
//        guard let dueDay = timeDifference.day, !self.publicSubmissions else {
//            return ("", UIColor.clear)
//        }
//
//        switch dueDay {
//        case Int.min..<0:
//            return ("⚐ Überfällig", highlightColor)
//        case 0..<1:
//            return ("⚐ In \(timeDifference.hour!) Stunden fällig", highlightColor)
//        case 1:
//            return ("⚐ Morgen fällig", highlightColor)
//        case 2:
//            return ("Übermorgen", UIColor.black)
//        case 3...7:
//            return ("In \(dueDay) Tagen", UIColor.black)
//        default:
//            return ("", UIColor.clear)
//        }
//    }
//
//    static var shortDateFormatter: DateFormatter = {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        return dateFormatter
//    }()
//
//    static func relativeDateString(for date: Date) -> String {
//        let calendar = NSCalendar.current
//        if calendar.isDateInYesterday(date) { return "Gestern" }
//        else if calendar.isDateInToday(date) { return "Heute" }
//        else if calendar.isDateInTomorrow(date) { return "Morgen" }
//        else {
//            return DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none)
//        }
//    }
//}

