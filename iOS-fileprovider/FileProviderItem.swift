//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import FileProvider
import MobileCoreServices


class FileProviderItem: NSObject, NSFileProviderItem {

    let itemIdentifier: NSFileProviderItemIdentifier
    let parentItemIdentifier: NSFileProviderItemIdentifier
    let capabilities: NSFileProviderItemCapabilities
    let filename: String
    let typeIdentifier: String

    let creationDate: Date?
    let contentModificationDate: Date?
    let childItemCount: NSNumber?
    let documentSize: NSNumber?

    let isUploaded: Bool
    let isUploading: Bool
    let uploadingError: Error?
    let isDownloaded: Bool
    let isDownloading: Bool
    let downloadingError: Error?

    let lastUsedDate: Date?
    let favoriteRank: NSNumber?
    let tagData: Data?

    let isTrashed: Bool
    let isShared: Bool

    init(file: File) {
        if #available(iOS 11.0, *) {
            self.itemIdentifier = file.id == FileHelper.rootDirectoryID ? NSFileProviderItemIdentifier.rootContainer : NSFileProviderItemIdentifier(file.id)
            if let parent = file.parentDirectory {
                self.parentItemIdentifier = parent.id == FileHelper.rootDirectoryID ? NSFileProviderItemIdentifier.rootContainer : NSFileProviderItemIdentifier(parent.id)
            } else {
                self.parentItemIdentifier = NSFileProviderItemIdentifier("")
            }
        } else {
            self.itemIdentifier = NSFileProviderItemIdentifier(file.id)
            self.parentItemIdentifier = file.parentDirectory != nil ? NSFileProviderItemIdentifier(file.parentDirectory!.id) : NSFileProviderItemIdentifier("")
        }

        self.capabilities = .allowsAll
        self.filename = file.name
        self.typeIdentifier = file.UTI ?? ""
        self.creationDate = file.createdAt
        self.contentModificationDate = file.updatedAt
        self.childItemCount = file.isDirectory ? NSNumber(value: file.contents.count) : NSNumber(value:0)
        self.documentSize = NSNumber(value: file.size)

        self.isUploaded = file.uploadState == .uploaded
        self.isUploading = file.uploadState == .uploading
        self.uploadingError = nil

        self.isDownloaded = file.downloadState == .downloaded
        self.isDownloading = file.downloadState == .downloading
        self.downloadingError = nil

        self.lastUsedDate = file.lastReadAt
        self.favoriteRank = NSNumber(value: file.favoriteRankValue)
        self.tagData = file.localTagData

        self.isTrashed = false
        self.isShared = false

        super.init()
    }
}
