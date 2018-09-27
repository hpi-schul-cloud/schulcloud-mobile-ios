//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import FileProvider

class FileEnumerator: NSObject, NSFileProviderEnumerator {

    // TODO: Implement this together with uploading
    let file: File

    init(file: File) {
        assert(!file.isDirectory)
        self.file = file
        super.init()
    }

    func invalidate() {
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {

    }

    func enumerateChanges(for observer: NSFileProviderChangeObserver, from syncAnchor: NSFileProviderSyncAnchor) {

    }
}
