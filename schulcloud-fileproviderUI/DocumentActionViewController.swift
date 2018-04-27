//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class DocumentActionViewController: UIDocumentPickerExtensionViewController {
    @IBOutlet weak var label: UILabel!

    lazy var fileCoordinator: NSFileCoordinator = {
        let result = NSFileCoordinator()
        result.purposeIdentifier = self.providerIdentifier
        return result
    }()

    override func prepareForPresentation(in mode: UIDocumentPickerMode) {

        switch mode {
        case .exportToService:
            label.text = "Export"
        case .moveToService:
            label.text = "Move"
        case .import:
            label.text = "Import"
        case .open:
            label.text = "Open"
        }
    }
}

