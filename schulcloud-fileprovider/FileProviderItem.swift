//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import FileProvider

class FileProviderItem: NSObject, NSFileProviderItem {

    let file: File

    init(file: File) {
        self.file = file
        super.init()
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        return NSFileProviderItemIdentifier(file.id)
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        guard let parent = file.parentDirectory else {
            return NSFileProviderItemIdentifier("")
        }
        return NSFileProviderItemIdentifier(parent.id)
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return .allowsAll
    }
    
    var filename: String {
        return file.name
    }
    
    var typeIdentifier: String {
        if file.isDirectory { return "public.folder"  }
        return file.mimeType ?? ""
    }
    
}
