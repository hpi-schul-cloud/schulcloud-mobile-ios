//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import Marshal
import MobileCoreServices

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
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

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
        file.createdAt = Date()
        file.updatedAt = file.createdAt

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

        let existed = result.count > 0

        let file = result.first ?? File(context: context)
        file.id = id

        let allowedCharacters = CharacterSet.whitespacesAndNewlines.inverted
        let remoteURLString = try data.value(for: "key") as String?
        let percentEncodedURLString = remoteURLString?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        file.remoteURL = URL(string: percentEncodedURLString ?? "")
        let thumbnailRemoteURLString = try? data.value(for: "thumbnail") as String
        let percentEncodedThumbnailURLString = thumbnailRemoteURLString?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        file.thumbnailRemoteURL = URL(string: percentEncodedThumbnailURLString ?? "")

        file.name = name
        file.isDirectory = isDirectory
        file.mimeType = isDirectory ? "public.folder" : try? data.value(for: "type")
        file.size = isDirectory ? 0 : try data.value(for: "size")
        file.createdAt = try data.value(for: "createdAt")
        if let updatedAt = try? data.value(for: "updatedAt") as Date {
            file.updatedAt = updatedAt
        } else {
            file.updatedAt = file.createdAt
        }

        if existed {
            file.downloadState = isDirectory ? .downloaded : .notDownloaded
            file.uploadState = .uploaded
        }

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
    static var localContainerURL: URL {
        if #available(iOS 11.0, *) {
            return NSFileProviderManager.default.documentStorageURL
        } else {
            // This returns the same URL as the iOS 11.0 documentStorageURL
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.schulcloud")!.appendingPathComponent("File Provider Storage")
        }
    }

    public var localFileName: String {
        return "\(self.id)__\(self.name)"
    }

    public var localURL: URL {
        let allowedCharacters = CharacterSet.whitespacesAndNewlines.inverted
        return File.localContainerURL.appendingPathComponent(self.localFileName.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!)
    }

    public var localThumbnailURL: URL {
        // TODO: This will be changed to direct to the Caches folder in the shared container.
        let cacheDirectoryURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return cacheDirectoryURL.appendingPathComponent("thumnail_\(self.id)_\(self.name)")
    }

    public var detail: String? {
        guard !self.isDirectory else {
            return nil
        }

        return ByteCountFormatter.string(fromByteCount: self.size, countStyle: .binary)
    }

    public var UTI: String? {
        guard !self.isDirectory else {
            return kUTTypeFolder as String
        }
        guard let mimeType = self.mimeType else {
            return ""
        }
        return File.mimeToUTI(mime: mimeType)
    }

    private static func mimeToUTI(mime: String) -> String? {
        let cfMime = mime as CFString
        guard let strPtr = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, cfMime, nil) else {
            return nil
        }
        let cfUTI = Unmanaged<CFString>.fromOpaque(strPtr.toOpaque()).takeUnretainedValue() as CFString
        return cfUTI as String
    }

}
