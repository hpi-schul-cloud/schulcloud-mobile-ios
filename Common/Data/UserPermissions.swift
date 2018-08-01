//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public struct UserPermissions: OptionSet { // swiftlint:disable:this type_body_length
    //                     MSB    LSB
    public typealias RawValue = (Int64, Int64)

    public let rawValue: RawValue

    public init(rawValue: RawValue ) {
        self.rawValue = rawValue
    }

    init(array: [String]) {
        self = array.compactMap { UserPermissions(str: $0) }.reduce(UserPermissions.none) { acc, permission -> UserPermissions in
            return acc.union(permission)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    init?(str: String) {
        switch str {
        case "ACCOUNT_CREATE":
            self = UserPermissions.accountCreate
        case "ACCOUNT_EDIT":
            self = UserPermissions.accountEdit
        case "ADMIN_VIEW":
            self = UserPermissions.adminView
        case "BASE_VIEW":
            self = UserPermissions.baseView
        case "CALENDAR_CREATE":
            self = UserPermissions.calendarCreate
        case "CALENDAR_EDIT":
            self = UserPermissions.calendarEdit
        case "CALENDAR_EVENT_CREATE":
            self = UserPermissions.calendarEventCreate
        case "CALENDAR_VIEW":
            self = UserPermissions.calendarView
        case "COMMENTS_CREATE":
            self = UserPermissions.commentsCreate
        case "COMMENTS_EDIT":
            self = UserPermissions.commentsEdit
        case "COMMENTS_VIEW":
            self = UserPermissions.commentsView
        case "CONTENT_NON_OER_VIEW":
            self = UserPermissions.contentNonOERView
        case "CONTENT_VIEW":
            self = UserPermissions.contentView
        case "COURSEGROUP_CREATE":
            self = UserPermissions.coursegroupCreate
        case "COURSEGROUP_EDIT":
            self = UserPermissions.coursegroupEdit
        case "COURSE_EDIT":
            self = UserPermissions.courseEdit
        case "DASHBOARD_VIEW":
            self = UserPermissions.dashboardView
        case "FEDERALSTATE_CREATE":
            self = UserPermissions.federalstateCreate
        case "FEDERALSTATE_EDIT":
            self = UserPermissions.federalstateEdit
        case "FEDERALSTATE_VIEW":
            self = UserPermissions.federalstateView
        case "FILESTORAGE_CREATE":
            self = UserPermissions.filestorageCreate
        case "FILESTORAGE_EDIT":
            self = UserPermissions.filestorageEdit
        case "FILESTORAGE_REMOVE":
            self = UserPermissions.filestorageRemove
        case "FILESTORAGE_VIEW":
            self = UserPermissions.filestorageView
        case "FILE_CREATE":
            self = UserPermissions.fileCreate
        case "FILE_DELETE":
            self = UserPermissions.fileDelete
        case "FILE_MOVE":
            self = UserPermissions.fileMove
        case "FOLDER_CREATE":
            self = UserPermissions.folderCreate
        case "FOLDER_DELETE":
            self = UserPermissions.folderDelete
        case "HELPDESK_CREATE":
            self = UserPermissions.helpdeskCreate
        case "HELPDESK_EDIT":
            self = UserPermissions.helpdeskEdit
        case "HELPDESK_VIEW":
            self = UserPermissions.helpdeskView
        case "HOMEWORK_CREATE":
            self = UserPermissions.homeworkCreate
        case "HOMEWORK_EDIT":
            self = UserPermissions.homeworkEdit
        case "HOMEWORK_VIEW":
            self = UserPermissions.homeworkView
        case "LESSONS_VIEW":
            self = UserPermissions.lessonsView
        case "LINK_CREATE":
            self = UserPermissions.linkCreate
        case "NEWS_CREATE":
            self = UserPermissions.newsCreate
        case "NEWS_EDIT":
            self = UserPermissions.newsEdit
        case "NEWS_VIEW":
            self = UserPermissions.newsView
        case "NOTIFICATION_CREATE":
            self = UserPermissions.notificationCreate
        case "NOTIFICATION_EDIT":
            self = UserPermissions.notificationEdit
        case "NOTIFICATION_VIEW":
            self = UserPermissions.notificationView
        case "PASSWORD_EDIT":
            self = UserPermissions.passwordEdit
        case "PWRECOVERY_CREATE":
            self = UserPermissions.pwrecoveryCreate
        case "PWRECOVERY_EDIT":
            self = UserPermissions.pwrecoveryEdit
        case "PWRECOVERY_VIEW":
            self = UserPermissions.pwrecoveryView
        case "RELEASES_CREATE":
            self = UserPermissions.releasesCreate
        case "RELEASES_EDIT":
            self = UserPermissions.releasesEdit
        case "RELEASES_VIEW":
            self = UserPermissions.releasesView
        case "ROLE_CREATE":
            self = UserPermissions.roleCreate
        case "ROLE_EDIT":
            self = UserPermissions.roleEdit
        case "ROLE_VIEW":
            self = UserPermissions.roleView
        case "SCHOOL_CREATE":
            self = UserPermissions.schoolCreate
        case "SCHOOL_EDIT":
            self = UserPermissions.schoolEdit
        case "SCHOOL_NEWS_EDIT":
            self = UserPermissions.schoolNewsEdit
        case "STUDENT_CREATE":
            self = UserPermissions.studentCreate
        case "SUBMISSIONS_CREATE":
            self = UserPermissions.submissionsCreate
        case "SUBMISSIONS_EDIT":
            self = UserPermissions.submissionsEdit
        case "SUBMISSIONS_VIEW":
            self = UserPermissions.submissionsView
        case "SYSTEM_CREATE":
            self = UserPermissions.systemCreate
        case "SYSTEM_EDIT":
            self = UserPermissions.systemEdit
        case "SYSTEM_VIEW":
            self = UserPermissions.systemView
        case "TEACHER_CREATE":
            self = UserPermissions.teacherCreate
        case "TOOL_CREATE":
            self = UserPermissions.toolCreate
        case "TOOL_EDIT":
            self = UserPermissions.toolEdit
        case "TOOL_NEW_VIEW":
            self = UserPermissions.toolNewView
        case "TOOL_VIEW":
            self = UserPermissions.toolView
        case "TOPIC_CREATE":
            self = UserPermissions.topicCreate
        case "TOPIC_EDIT":
            self = UserPermissions.topicEdit
        case "TOPIC_VIEW":
            self = UserPermissions.topicView
        case "USERGROUP_CREATE":
            self = UserPermissions.usergroupCreate
        case "USERGROUP_EDIT":
            self = UserPermissions.usergroupEdit
        case "USERGROUP_VIEW":
            self = UserPermissions.usergroupView
        case "USER_CREATE":
            self = UserPermissions.userCreate
        case "USER_EDIT":
            self = UserPermissions.userEdit
        case "USER_VIEW":
            self = UserPermissions.userView
        default:
            return nil
        }
    }

    public var description: String {
        switch self {
        case UserPermissions.homeworkView:
            return "HOMEWORK_VIEW"
        case UserPermissions.dashboardView:
            return "DASHBOAD_VIEW"
        case UserPermissions.notificationView:
            return "NOTIFICATION_VIEW"
        case UserPermissions.calendarView:
            return "CALENDAR_VIEW"
        case UserPermissions.contentView:
            return "CONTENT_VIEW"
        case UserPermissions.newsView:
            return "NEWS_VIEW"
        default:
            return "\(self.rawValue)"
        }
    }

    public static let none = UserPermissions(rawValue: (0, 0))
    public static let accountCreate = UserPermissions(rawValue: ( 0, 1 << 0) )
    public static let accountEdit = UserPermissions(rawValue: ( 0, 1 << 1 ) )
    public static let adminView = UserPermissions(rawValue: ( 0, 1 << 2 ) )
    public static let baseView = UserPermissions(rawValue: ( 0, 1 << 3 ) )
    public static let calendarCreate = UserPermissions(rawValue: ( 0, 1 << 4 ) )
    public static let calendarEdit = UserPermissions(rawValue: ( 0, 1 << 5 ) )
    public static let calendarEventCreate = UserPermissions(rawValue: ( 0, 1 << 6 ) )
    public static let calendarView = UserPermissions(rawValue: ( 0, 1 << 7 ) )
    public static let commentsCreate = UserPermissions(rawValue: ( 0, 1 << 8 ) )
    public static let commentsEdit = UserPermissions(rawValue: ( 0, 1 << 9 ) )
    public static let commentsView = UserPermissions(rawValue: ( 0, 1 << 10 ) )
    public static let contentNonOERView = UserPermissions(rawValue: ( 0, 1 << 11 ) )
    public static let contentView = UserPermissions(rawValue: ( 0, 1 << 12 ) )
    public static let coursegroupCreate = UserPermissions(rawValue: ( 0, 1 << 13 ) )
    public static let coursegroupEdit = UserPermissions(rawValue: ( 0, 1 << 14 ) )
    public static let courseEdit = UserPermissions(rawValue: ( 0, 1 << 15 ) )
    public static let dashboardView = UserPermissions(rawValue: ( 0, 1 << 16 ) )
    public static let federalstateCreate = UserPermissions(rawValue: ( 0, 1 << 17 ) )
    public static let federalstateEdit = UserPermissions(rawValue: ( 0, 1 << 18 ) )
    public static let federalstateView = UserPermissions(rawValue: ( 0, 1 << 19 ) )
    public static let filestorageCreate = UserPermissions(rawValue: ( 0, 1 << 20 ) )
    public static let filestorageEdit = UserPermissions(rawValue: ( 0, 1 << 21 ) )
    public static let filestorageRemove = UserPermissions(rawValue: ( 0, 1 << 22 ) )
    public static let filestorageView = UserPermissions(rawValue: ( 0, 1 << 23 ) )
    public static let fileCreate = UserPermissions(rawValue: ( 0, 1 << 24 ) )
    public static let fileDelete = UserPermissions(rawValue: ( 0, 1 << 25 ) )
    public static let fileMove = UserPermissions(rawValue: ( 0, 1 << 26 ) )
    public static let folderCreate = UserPermissions(rawValue: ( 0, 1 << 27 ) )
    public static let folderDelete = UserPermissions(rawValue: ( 0, 1 << 28 ) )
    public static let helpdeskCreate = UserPermissions(rawValue: ( 0, 1 << 29 ) )
    public static let helpdeskEdit = UserPermissions(rawValue: ( 0, 1 << 30 ) )
    public static let helpdeskView = UserPermissions(rawValue: ( 0, 1 << 31 ) )
    public static let homeworkCreate = UserPermissions(rawValue: ( 0, 1 << 32 ) )
    public static let homeworkEdit = UserPermissions(rawValue: ( 0, 1 << 33 ) )
    public static let homeworkView = UserPermissions(rawValue: ( 0, 1 << 34 ) )
    public static let lessonsView = UserPermissions(rawValue: ( 0, 1 << 35 ) )
    public static let linkCreate = UserPermissions(rawValue: ( 0, 1 << 36 ) )
    public static let newsCreate = UserPermissions(rawValue: ( 0, 1 << 37 ) )
    public static let newsEdit = UserPermissions(rawValue: ( 0, 1 << 38 ) )
    public static let newsView = UserPermissions(rawValue: ( 0, 1 << 39 ) )
    public static let notificationCreate = UserPermissions(rawValue: ( 0, 1 << 40 ) )
    public static let notificationEdit = UserPermissions(rawValue: ( 0, 1 << 41 ) )
    public static let notificationView = UserPermissions(rawValue: ( 0, 1 << 42 ) )
    public static let passwordEdit = UserPermissions(rawValue: ( 0, 1 << 43 ) )
    public static let pwrecoveryCreate = UserPermissions(rawValue: ( 0, 1 << 44 ) )
    public static let pwrecoveryEdit = UserPermissions(rawValue: ( 0, 1 << 45 ) )
    public static let pwrecoveryView = UserPermissions(rawValue: ( 0, 1 << 46 ) )
    public static let releasesCreate = UserPermissions(rawValue: ( 0, 1 << 47 ) )
    public static let releasesEdit = UserPermissions(rawValue: ( 0, 1 << 48 ) )
    public static let releasesView = UserPermissions(rawValue: ( 0, 1 << 49 ) )
    public static let roleCreate = UserPermissions(rawValue: ( 0, 1 << 50 ) )
    public static let roleEdit = UserPermissions(rawValue: ( 0, 1 << 51 ) )
    public static let roleView = UserPermissions(rawValue: ( 0, 1 << 52 ) )
    public static let schoolCreate = UserPermissions(rawValue: ( 0, 1 << 53 ) )
    public static let schoolEdit = UserPermissions(rawValue: ( 0, 1 << 54 ) )
    public static let schoolNewsEdit = UserPermissions(rawValue: ( 0, 1 << 55 ) )
    public static let studentCreate = UserPermissions(rawValue: ( 0, 1 << 56 ) )
    public static let submissionsCreate = UserPermissions(rawValue: ( 0, 1 << 57 ) )
    public static let submissionsEdit = UserPermissions(rawValue: ( 0, 1 << 58 ) )
    public static let submissionsView = UserPermissions(rawValue: ( 0, 1 << 59 ) )
    public static let systemCreate = UserPermissions(rawValue: ( 0, 1 << 60 ) )
    public static let systemEdit = UserPermissions(rawValue: ( 0, 1 << 61 ) )
    public static let systemView = UserPermissions(rawValue: ( 0, 1 << 62) )
    public static let teacherCreate = UserPermissions(rawValue: ( 0, 1 << 63 ) )
    public static let toolCreate = UserPermissions(rawValue: ( 1 << 0, 0 ) )
    public static let toolEdit = UserPermissions(rawValue: ( 1 << 1, 0 ) )
    public static let toolNewView = UserPermissions(rawValue: ( 1 << 2, 0 ) )
    public static let toolView = UserPermissions(rawValue: ( 1 << 3, 0 ) )
    public static let topicCreate = UserPermissions(rawValue: ( 1 << 4, 0 ) )
    public static let topicEdit = UserPermissions(rawValue: ( 1 << 5, 0 ) )
    public static let topicView = UserPermissions(rawValue: ( 1 << 6, 0 ) )
    public static let usergroupCreate = UserPermissions(rawValue: ( 1 << 7, 0 ) )
    public static let usergroupEdit = UserPermissions(rawValue: ( 1 << 8, 0 ) )
    public static let usergroupView = UserPermissions(rawValue: ( 1 << 9, 0 ) )
    public static let userCreate = UserPermissions(rawValue: ( 1 << 10, 0 ) )
    public static let userEdit = UserPermissions(rawValue: ( 1 << 11, 0 ) )
    public static let userView = UserPermissions(rawValue: ( 1 << 12, 0 ) )

    // NOTE: So far, only filestorageCreate and removed are handled on the backend, I guess in the future, fileCreate/fileMove/fileDelete will be handled
    public static let creatingFiles: UserPermissions = [.filestorageCreate]
    public static let deletingFiles: UserPermissions = [.filestorageRemove]
    public static let movingFiles: UserPermissions = [.filestorageCreate]
}

extension UserPermissions: Equatable {
    public static func == (lhs: UserPermissions, rhs: UserPermissions) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension UserPermissions: SetAlgebra {
    // This is required by SetAlgebra protocol, user should use UserPermissions.none or rawValue init instead
    public init() {
        self = UserPermissions.none
    }

    public func intersection(_ other: UserPermissions) -> UserPermissions {
        return UserPermissions(rawValue: (self.rawValue.0 & other.rawValue.0,
                                          self.rawValue.1 & other.rawValue.1))
    }

    public func union(_ other: UserPermissions) -> UserPermissions {
        return UserPermissions(rawValue: (self.rawValue.0 | other.rawValue.0,
                                          self.rawValue.1 | other.rawValue.1))
    }

    public mutating func formUnion(_ other: UserPermissions) {
        self = self.union(other)
    }

    public mutating func formIntersection(_ other: UserPermissions) {
        self = self.intersection(other)
    }

    public mutating func formSymmetricDifference(_ other: UserPermissions) {
        self = UserPermissions(rawValue: (self.rawValue.0 - (self.rawValue.0 & other.rawValue.0),
                                          self.rawValue.1 - (self.rawValue.1 & other.rawValue.1)) )
    }
}
