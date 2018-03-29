//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

struct UserPermissions: OptionSet {
    //                     MSB    LSB
    typealias RawValue = (Int64, Int64)
    let rawValue: RawValue
    init(rawValue: RawValue ) {
        self.rawValue = rawValue
    }

    init(array: [String]) {
        self = array.flatMap{ UserPermissions(str: $0) }.reduce(UserPermissions.none, { (acc, permission) -> UserPermissions in
            return acc.union(permission)
        })
    }

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
            self = UserPermissions.calendarEvent_create
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
            self = UserPermissions.schoolNews_edit
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
            self = UserPermissions.toolNew_view
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

    var description: String {
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

    static let none = UserPermissions(rawValue: (0, 0))
    static let accountCreate = UserPermissions(rawValue: ( 0, 1 << 0) )
    static let accountEdit = UserPermissions(rawValue: ( 0, 1 << 1 ) )
    static let adminView = UserPermissions(rawValue: ( 0, 1 << 2 ) )
    static let baseView = UserPermissions(rawValue: ( 0, 1 << 3 ) )
    static let calendarCreate = UserPermissions(rawValue: ( 0, 1 << 4 ) )
    static let calendarEdit = UserPermissions(rawValue: ( 0, 1 << 5 ) )
    static let calendarEvent_create = UserPermissions(rawValue: ( 0, 1 << 6 ) )
    static let calendarView = UserPermissions(rawValue: ( 0, 1 << 7 ) )
    static let commentsCreate = UserPermissions(rawValue: ( 0, 1 << 8 ) )
    static let commentsEdit = UserPermissions(rawValue: ( 0, 1 << 9 ) )
    static let commentsView = UserPermissions(rawValue: ( 0, 1 << 10 ) )
    static let contentNonOERView = UserPermissions(rawValue: ( 0, 1 << 11 ) )
    static let contentView = UserPermissions(rawValue: ( 0, 1 << 12 ) )
    static let coursegroupCreate = UserPermissions(rawValue: ( 0, 1 << 13 ) )
    static let coursegroupEdit = UserPermissions(rawValue: ( 0, 1 << 14 ) )
    static let courseEdit = UserPermissions(rawValue: ( 0, 1 << 15 ) )
    static let dashboardView = UserPermissions(rawValue: ( 0, 1 << 16 ) )
    static let federalstateCreate = UserPermissions(rawValue: ( 0, 1 << 17 ) )
    static let federalstateEdit = UserPermissions(rawValue: ( 0, 1 << 18 ) )
    static let federalstateView = UserPermissions(rawValue: ( 0, 1 << 19 ) )
    static let filestorageCreate = UserPermissions(rawValue: ( 0, 1 << 20 ) )
    static let filestorageEdit = UserPermissions(rawValue: ( 0, 1 << 21 ) )
    static let filestorageRemove = UserPermissions(rawValue: ( 0, 1 << 22 ) )
    static let filestorageView = UserPermissions(rawValue: ( 0, 1 << 23 ) )
    static let fileCreate = UserPermissions(rawValue: ( 0, 1 << 24 ) )
    static let fileDelete = UserPermissions(rawValue: ( 0, 1 << 25 ) )
    static let fileMove = UserPermissions(rawValue: ( 0, 1 << 26 ) )
    static let folderCreate = UserPermissions(rawValue: ( 0, 1 << 27 ) )
    static let folderDelete = UserPermissions(rawValue: ( 0, 1 << 28 ) )
    static let helpdeskCreate = UserPermissions(rawValue: ( 0, 1 << 29 ) )
    static let helpdeskEdit = UserPermissions(rawValue: ( 0, 1 << 30 ) )
    static let helpdeskView = UserPermissions(rawValue: ( 0, 1 << 31 ) )
    static let homeworkCreate = UserPermissions(rawValue: ( 0, 1 << 32 ) )
    static let homeworkEdit = UserPermissions(rawValue: ( 0, 1 << 33 ) )
    static let homeworkView = UserPermissions(rawValue: ( 0, 1 << 34 ) )
    static let lessonsView = UserPermissions(rawValue: ( 0, 1 << 35 ) )
    static let linkCreate = UserPermissions(rawValue: ( 0, 1 << 36 ) )
    static let newsCreate = UserPermissions(rawValue: ( 0, 1 << 37 ) )
    static let newsEdit = UserPermissions(rawValue: ( 0, 1 << 38 ) )
    static let newsView = UserPermissions(rawValue: ( 0, 1 << 39 ) )
    static let notificationCreate = UserPermissions(rawValue: ( 0, 1 << 40 ) )
    static let notificationEdit = UserPermissions(rawValue: ( 0, 1 << 41 ) )
    static let notificationView = UserPermissions(rawValue: ( 0, 1 << 42 ) )
    static let passwordEdit = UserPermissions(rawValue: ( 0, 1 << 43 ) )
    static let pwrecoveryCreate = UserPermissions(rawValue: ( 0, 1 << 44 ) )
    static let pwrecoveryEdit = UserPermissions(rawValue: ( 0, 1 << 45 ) )
    static let pwrecoveryView = UserPermissions(rawValue: ( 0, 1 << 46 ) )
    static let releasesCreate = UserPermissions(rawValue: ( 0, 1 << 47 ) )
    static let releasesEdit = UserPermissions(rawValue: ( 0, 1 << 48 ) )
    static let releasesView = UserPermissions(rawValue: ( 0, 1 << 49 ) )
    static let roleCreate = UserPermissions(rawValue: ( 0, 1 << 50 ) )
    static let roleEdit = UserPermissions(rawValue: ( 0, 1 << 51 ) )
    static let roleView = UserPermissions(rawValue: ( 0, 1 << 52 ) )
    static let schoolCreate = UserPermissions(rawValue: ( 0, 1 << 53 ) )
    static let schoolEdit = UserPermissions(rawValue: ( 0, 1 << 54 ) )
    static let schoolNews_edit = UserPermissions(rawValue: ( 0, 1 << 55 ) )
    static let studentCreate = UserPermissions(rawValue: ( 0, 1 << 56 ) )
    static let submissionsCreate = UserPermissions(rawValue: ( 0, 1 << 57 ) )
    static let submissionsEdit = UserPermissions(rawValue: ( 0, 1 << 58 ) )
    static let submissionsView = UserPermissions(rawValue: ( 0, 1 << 59 ) )
    static let systemCreate = UserPermissions(rawValue: ( 0, 1 << 60 ) )
    static let systemEdit = UserPermissions(rawValue: ( 0, 1 << 61 ) )
    static let systemView = UserPermissions(rawValue: ( 0, 1 << 62) )
    static let teacherCreate = UserPermissions(rawValue: ( 0, 1 << 63 ) )
    static let toolCreate = UserPermissions(rawValue: ( 1 << 0, 0 ) )
    static let toolEdit = UserPermissions(rawValue: ( 1 << 1, 0 ) )
    static let toolNew_view = UserPermissions(rawValue: ( 1 << 2, 0 ) )
    static let toolView = UserPermissions(rawValue: ( 1 << 3, 0 ) )
    static let topicCreate = UserPermissions(rawValue: ( 1 << 4, 0 ) )
    static let topicEdit = UserPermissions(rawValue: ( 1 << 5, 0 ) )
    static let topicView = UserPermissions(rawValue: ( 1 << 6, 0 ) )
    static let usergroupCreate = UserPermissions(rawValue: ( 1 << 7, 0 ) )
    static let usergroupEdit = UserPermissions(rawValue: ( 1 << 8, 0 ) )
    static let usergroupView = UserPermissions(rawValue: ( 1 << 9, 0 ) )
    static let userCreate = UserPermissions(rawValue: ( 1 << 10, 0 ) )
    static let userEdit = UserPermissions(rawValue: ( 1 << 11, 0 ) )
    static let userView = UserPermissions(rawValue: ( 1 << 12, 0 ) )

    //NOTE: So far, only filestorageCreate and removed are handled on the backend, I guess in the future, fileCreate/fileMove/fileDelete will be handled
    static let creatingFiles: UserPermissions = [.filestorageCreate]
    static let deletingFiles: UserPermissions = [.filestorageRemove]
    static let movingFiles: UserPermissions = [.filestorageCreate]
}

extension UserPermissions: Equatable {
    static func == (lhs: UserPermissions, rhs: UserPermissions) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension UserPermissions: SetAlgebra {
    // This is required by SetAlgebra protocol, user should use UserPermissions.none or rawValue init instead
    init() {
        self = UserPermissions.none
    }

    func intersection(_ other: UserPermissions) -> UserPermissions {
        return UserPermissions(rawValue: (self.rawValue.0 & other.rawValue.0,
                                          self.rawValue.1 & other.rawValue.1))
    }

    func union(_ other: UserPermissions) -> UserPermissions {
        return UserPermissions(rawValue: (self.rawValue.0 | other.rawValue.0,
                                          self.rawValue.1 | other.rawValue.1))
    }

    mutating func formUnion(_ other: UserPermissions) {
        self = self.union(other)
    }

    mutating func formIntersection(_ other: UserPermissions) {
        self = self.intersection(other)
    }

    mutating func formSymmetricDifference(_ other: UserPermissions) {
        self = UserPermissions(rawValue: (self.rawValue.0 - (self.rawValue.0 & other.rawValue.0),
                                          self.rawValue.1 - (self.rawValue.1 & other.rawValue.1)) )
    }
}

