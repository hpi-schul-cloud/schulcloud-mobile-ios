//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import Marshal

public final class File: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }

    @NSManaged public var id: String
    @NSManaged public var remoteURL: URL?
    @NSManaged public var thumbnailRemoteURL: URL?
    @NSManaged public var name: String
    @NSManaged public var isDirectory: Bool
    @NSManaged public var mimeType: String?
    @NSManaged public var size: Int64

    @NSManaged private var permissionsValue: Int64
    @NSManaged private var downloadStateValue: Int64
    @NSManaged private var uploadStateValue: Int64

    @NSManaged public var parentDirectory: File?
    @NSManaged public var contents: Set<File>
}

public extension File {

    public struct Permissions: OptionSet {
        public let rawValue: Int64

        static let read = Permissions(rawValue: 1 << 1)
        static let write = Permissions(rawValue: 1 << 2)

        static let readWrite: Permissions = [.read, .write]

        public init(rawValue: Int64) {
            self.rawValue = rawValue
        }

        public init?(str: String) {
            switch str {
            case "can_read":
                self = Permissions.read
            case "can_write":
                self = Permissions.write
            default:
                return nil
            }
        }

        init(json: MarshaledObject) throws {
            let fetchedPersmissions: [String] = try json.value(for: "permissions")
            let permissions: [Permissions] = fetchedPersmissions.compactMap { Permissions(str: $0) }
            self.rawValue = permissions.reduce([]) { acc, permission -> Permissions in
                return acc.union(permission)
            }.rawValue
        }
    }

    var permissions: Permissions {
        get {
            return Permissions(rawValue: self.permissionsValue)
        }
        set {
            self.permissionsValue = newValue.rawValue
        }
    }
}

public extension File {
    public enum DownloadState: Int64 {
        case notDownloaded = 0
        case downloading = 1
        case downloaded = 2
        case downloadFailed = 3
    }

    public var downloadState: DownloadState {
        get {
            return DownloadState(rawValue: self.downloadStateValue) ?? .notDownloaded
        }

        set {
            self.downloadStateValue = newValue.rawValue
        }
    }
}

public extension File {
    public enum UploadState: Int64 {
        case notUploaded = 0
        case uploading = 1
        case uploaded = 2
        case uploadError = 3
    }

    public var uploadState: UploadState {
        get {
            return UploadState(rawValue: self.uploadStateValue) ?? .notUploaded
        }
        set {
            self.uploadStateValue = newValue.rawValue
        }
    }
}

extension File {

    @discardableResult static func createLocal(context: NSManagedObjectContext,
                                               id: String,
                                               name: String,
                                               parentFolder: File?,
                                               isDirectory: Bool,
                                               remoteURL: URL? = nil) -> File {
        let file = File(context: context)
        file.id = id

        file.remoteURL = remoteURL
        file.thumbnailRemoteURL = nil

        file.name = name
        file.isDirectory = isDirectory
        file.parentDirectory = parentFolder

        file.permissions = .read
        file.uploadState = .uploaded
        file.downloadState = . downloaded

        return file
    }

    static func createOrUpdate(inContext context: NSManagedObjectContext, parentFolder: File, isDirectory: Bool, data: MarshaledObject) throws -> File {
        let name: String = try data.value(for: "name")
        let id: String = try data.value(for: "_id")

        let fetchRequest = NSFetchRequest<File>(entityName: "File")
        let idPredicate = NSPredicate(format: "id == %@", id)
        let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", parentFolder)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [idPredicate, parentFolderPredicate])

        let result = try context.fetch(fetchRequest)
        if result.count > 1 {
            throw SCError.coreDataMoreThanOneObjectFound
        }

        let file = result.first ?? File(context: context)
        file.id = id

        let allowedCharacters = CharacterSet.whitespacesAndNewlines.inverted
        let remoteURLString = try data.value(for: "key") as String?
        let percentEncodedURLString = remoteURLString?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        file.remoteURL = URL(string: percentEncodedURLString ?? "")
        let thumbnailRemoteURLString = try data.value(for: "thumbnail") as String?
        let percentEncodedThumbnailURLString = thumbnailRemoteURLString?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        file.thumbnailRemoteURL = URL(string: percentEncodedThumbnailURLString ?? "")

        file.name = name
        file.isDirectory = isDirectory
        file.mimeType = try? data.value(for: "type")
        file.size = try data.value(for: "size")

        file.downloadState = isDirectory ? .downloaded : .notDownloaded
        file.uploadState = .uploaded

        file.parentDirectory = parentFolder

        let permissionsObject: [MarshaledObject]? = try? data.value(for: "permissions")
        let userPermission: MarshaledObject? = permissionsObject?.first { data -> Bool in
            if let userId: String = try? data.value(for: "userId"),
                userId == Globals.account?.userId { // find permission for current user
                return true
            }

            return false
        }

        if let userPermission = userPermission {
            file.permissions = try Permissions(json: userPermission)
        }

        return file
    }
}

// MARK: computed properties
extension File {

    // TODO: replace with fileprovidermanager when implemented
    static var localContainerURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.schulcloud")!.appendingPathComponent("File Provider Storage")
    }

    public var localFileName: String {
        return "\(self.id)__\(self.name)"
    }

    public var localURL: URL {
        let allowedCharacters = CharacterSet.whitespacesAndNewlines.inverted
        return File.localContainerURL.appendingPathComponent(self.localFileName.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!)
    }

    public var detail: String? {
        guard !self.isDirectory else {
            return nil
        }

        return ByteCountFormatter.string(fromByteCount: self.size, countStyle: .binary)
    }
}
