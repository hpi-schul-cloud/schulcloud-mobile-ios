//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit
import Common

class ResourceCell: UICollectionViewCell {
    @IBOutlet weak var resourceImage: UIImageView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    
    
    override func awakeFromNib() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 6.0
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor(white: 0.7, alpha: 1.0).cgColor
    }
    
    func configure(for course: ContentResource) {
        self.headingLabel.text = course.title
        
        self.tagsLabel.text = course.tags[0]
    }
}
