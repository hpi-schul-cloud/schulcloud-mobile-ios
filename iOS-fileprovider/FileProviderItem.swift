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
        self.itemIdentifier = file.id == FileHelper.rootDirectoryID ? NSFileProviderItemIdentifier.rootContainer : NSFileProviderItemIdentifier(file.id)
        if let parent = file.parentDirectory {
            self.parentItemIdentifier = parent.id == FileHelper.rootDirectoryID ? NSFileProviderItemIdentifier.rootContainer : NSFileProviderItemIdentifier(parent.id)
        } else {
            self.parentItemIdentifier = NSFileProviderItemIdentifier("")
        }

        self.capabilities = .allowsReading
        self.filename = file.name
        self.typeIdentifier = file.UTI ?? ""
        self.creationDate = file.createdAt
        self.contentModificationDate = file.updatedAt
        self.childItemCount = file.isDirectory ? (!file.contents.isEmpty ? NSNumber(value: file.contents.count) : nil) : nil
        self.documentSize = file.isDirectory ? nil : NSNumber(value: file.size)

        self.isUploaded = file.uploadState == .uploaded
        self.isUploading = file.uploadState == .uploading
        self.uploadingError = nil

        self.isDownloaded = file.downloadState == .downloaded
        self.isDownloading = file.downloadState == .downloading
        self.downloadingError = nil

        self.lastUsedDate = file.lastReadAt

        if file.isDirectory,
            let rankValueData = file.favoriteRankData,
            let rankValue: UInt64 = rankValueData.withUnsafeBytes({ $0.baseAddress?.load(as: UInt64.self) }) {
            self.favoriteRank = file.isDirectory ? NSNumber(value: rankValue) : nil
        } else {
            self.favoriteRank = nil
        }

        self.tagData = file.localTagData

        self.isTrashed = false
        self.isShared = false

        super.init()
    }
}
