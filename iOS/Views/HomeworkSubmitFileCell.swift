//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class HomeworkSubmitFileCell: UITableViewCell {

    @IBOutlet private weak var fileName: UILabel!
    @IBOutlet private weak var fileStateImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.fileStateImageView?.tintColor = Brand.default.colors.primary
    }

    func configure(withTitle title: String?, image: UIImage?) {
        self.fileName.text = title
        self.fileStateImageView?.image = image?.withRenderingMode(.alwaysTemplate)
    }

}
