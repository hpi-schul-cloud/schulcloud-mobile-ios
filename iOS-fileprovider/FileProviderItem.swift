//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import FileProvider
import MobileCoreServices

extension File: NSFileProviderItem {
    public var itemIdentifier: NSFileProviderItemIdentifier {
        guard self.id != FileHelper.rootDirectoryID else {
            return NSFileProviderItemIdentifier.rootContainer
        }
        return NSFileProviderItemIdentifier(self.id)
    }

    public var parentItemIdentifier: NSFileProviderItemIdentifier {
        guard let parentId = self.parentDirectory?.id else {
            return NSFileProviderItemIdentifier("")
        }
        if parentId == FileHelper.rootDirectoryID {
            return NSFileProviderItemIdentifier.rootContainer
        }
        return NSFileProviderItemIdentifier(parentId)
    }

    public var capabilities: NSFileProviderItemCapabilities {
        return .allowsAll
    }

    public var filename: String {
        return self.name
    }

    public var typeIdentifier: String {
        return self.UTI ?? ""
    }

    public var creationDate: Date? {
        return self.createdAt
    }

    public var contentModificationDate: Date? {
        return self.updatedAt
    }

    public var childItemCount: NSNumber? {
        guard isDirectory else {
            return nil
        }

        return NSNumber(value: self.contents.count)
    }

    public var documentSize: NSNumber? {
        return NSNumber(value: self.size)
    }
}
