//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import Marshal
import MobileCoreServices

public final class File: NSManagedObject {

    public enum Owner {
        case user(id: String)
        case course(id: String)
        case team
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }

    @NSManaged public var id: String
    @NSManaged public var thumbnailRemoteURL: URL?
    @NSManaged public var name: String
    @NSManaged public var isDirectory: Bool
    @NSManaged public var mimeType: String?
    @NSManaged public var size: Int64
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var lastReadAt: Date
    @NSManaged var ownerId: String
    @NSManaged var ownerTypeStorage: String

    @NSManaged public var favoriteRankData: Data?
    @NSManaged public var localTagData: Data?

    @NSManaged private var permissionsValue: Int64
    @NSManaged private var downloadStateValue: Int64
    @NSManaged private var uploadStateValue: Int64

    @NSManaged public var parentDirectory: File?
    @NSManaged public var contents: Set<File>

    var owner: Owner {
        get {
            switch self.ownerTypeStorage {
            case "user":
                return .user(id: self.ownerId)
            case "course":
                return .course(id: self.ownerId)
            case "team":
                return .team
            default:
                fatalError("Unrecognized owner type")
            }
        }

        set {
            switch newValue {
            case .course(let id):
                self.ownerTypeStorage = "course"
                self.ownerId = id
            case .user(let id):
                self.ownerTypeStorage = "user"
                self.ownerId = id
            case .team:
                self.ownerTypeStorage = "team"
                self.ownerId = "someid"
            }
        }
    }
}

public extension File {

    public struct Permissions: OptionSet {
        public let rawValue: Int64

        static let read = Permissions(rawValue: 1 << 0)
        static let write = Permissions(rawValue: 1 << 1)
        static let create = Permissions(rawValue: 1 << 2)
        static let delete = Permissions(rawValue: 1 << 3)

        static let readWrite: Permissions = [.read, .write]

        public init(rawValue: Int64) {
            self.rawValue = rawValue
        }

        init(str: String) {
            switch str {
            case "delete":
                self = .delete
            case "write":
                self = .write
            case "read":
                self = .read
            case "create":
                self = .create
            default:
                fatalError("Unknown permission type")
            }
        }

        init(json: MarshaledObject) throws {
            self.rawValue = try ["delete", "write", "create", "read"].filter { return try json.value(for: $0) }.map(Permissions.init(str:)).reduce([]) { acc, permission -> Permissions in
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
            guard !FileManager.default.fileExists(atPath: self.localURL.path) else {
                return .downloaded
            }

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
                                               owner: File.Owner) -> File {
        let file = File(context: context)
        file.id = id

        file.thumbnailRemoteURL = nil

        file.name = name
        file.isDirectory = isDirectory
        file.parentDirectory = parentFolder
        file.createdAt = Date()
        file.updatedAt = file.createdAt
        file.lastReadAt = file.createdAt

        file.owner = owner

        file.favoriteRankData = nil
        file.localTagData = nil

        file.permissions = .read
        file.uploadState = .uploaded
        file.downloadState = . downloaded

        return file
    }

    static func createOrUpdate(inContext context: NSManagedObjectContext, parentFolder: File, data: MarshaledObject) throws -> File {
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

        let existed = !result.isEmpty

        let file = result.first ?? File(context: context)
        file.id = id

        let allowedCharacters = CharacterSet.whitespacesAndNewlines.inverted
        let thumbnailRemoteURLString = try? data.value(for: "thumbnail") as String
        let percentEncodedThumbnailURLString = thumbnailRemoteURLString?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        file.thumbnailRemoteURL = URL(string: percentEncodedThumbnailURLString ?? "")

        file.name = name
        file.isDirectory = try data.value(for: "isDirectory")
        file.mimeType = file.isDirectory ? "public.folder" : try? data.value(for: "type")
        file.size = file.isDirectory ? 0 : try data.value(for: "size")
        file.createdAt = try data.value(for: "createdAt")
        if let updatedAt = try? data.value(for: "updatedAt") as Date {
            file.updatedAt = updatedAt
        } else {
            file.updatedAt = file.createdAt
        }

        file.ownerId = try data.value(for: "owner")
        file.ownerTypeStorage = try data.value(for: "refOwnerModel")

        file.lastReadAt = file.createdAt
        if existed && file.isDirectory {
            file.downloadState = .downloaded
        }

        file.uploadState = .uploaded

        file.parentDirectory = parentFolder

        let user = context.typedObject(with: Globals.currentUser!.objectID) as User

        let permissionsObject: [MarshaledObject]? = try? data.value(for: "permissions")
        let rolePermission = try permissionsObject?.filter { try $0.value(for: "refPermModel") == "role" }.first(where: { user.roles.contains(try $0.value(for: "refId")) })
        let userPermission = try permissionsObject?.filter { try $0.value(for: "refPermModel") == "user" }.first(where: { try $0.value(for: "refId") == user.id })

        if let userPermission = userPermission {
            file.permissions = try Permissions(json: userPermission)
        } else if let rolePermission = rolePermission {
            file.permissions = try Permissions(json: rolePermission)
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
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.appGroupIdentifier!)!.appendingPathComponent("File Provider Storage")
        }
    }

    static var thumbnailContainerURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.appGroupIdentifier!)!.appendingPathComponent("Caches")
    }

    public var localFileName: String {
        return "\(self.id)__\(self.name)"
    }

    public static func id(from url: URL) -> String? {
        // resolve the given URL to a persistent identifier using a database
        // Filename of format fileid__name, extract id from filename, no need to hit the DB
        let filename = url.lastPathComponent
        guard let localURLSeparatorRange = filename.range(of: "__") else {
            return nil
        }

        return String(filename[filename.startIndex..<localURLSeparatorRange.lowerBound])
    }

    public var localURL: URL {
        let allowedCharacters = CharacterSet.whitespacesAndNewlines.inverted
        return File.localContainerURL.appendingPathComponent(self.localFileName.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!)
    }

    public var localThumbnailURL: URL {
        return File.thumbnailContainerURL.appendingPathComponent("thumnail_\(self.thumbnailRemoteURL!.lastPathComponent)")
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

// MARK: Convenient requests
extension File {
    public static func by(id: String, in context: NSManagedObjectContext) -> File? {
        assert(!id.isEmpty)
        let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        let result = context.fetchSingle(fetchRequest)
        guard let value = result.value else {
            log.error("Didn't find file with id: %@", id, error: result.error)
            return nil
        }

        return value
    }

    public static func with(parentId id: String, in context: NSManagedObjectContext) -> [File]? {
        assert(!id.isEmpty)

        let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
        fetchRequest.predicate = NSPredicate(format: "parentDirectory.id == %@", id)

        let result = context.fetchMultiple(fetchRequest)
        guard let value = result.value else {
            log.error("Error looking for item with parentID: %@", id, error: result.error)
            return nil
        }

        return value
    }

    public static func with(ids: [String], in context: NSManagedObjectContext) -> [File]? {
        assert(!ids.isEmpty)
        assert(!(ids.map { $0.isEmpty }.contains(true))) // no empty string the list of ids

        let fetchRequest = File.fetchRequest() as NSFetchRequest<File>
        fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)

        let result = context.fetchMultiple(fetchRequest)
        guard let value = result.value else {
            log.error("Fetching ids failed", error: result.error)
            return nil
        }

        return value
    }
}
