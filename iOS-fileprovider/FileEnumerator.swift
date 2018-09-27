//
//  FileEnumerator.swift
//  iOS
//
//  Created by Florian Morel on 27.09.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
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
