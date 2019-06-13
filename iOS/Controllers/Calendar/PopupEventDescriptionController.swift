//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class PopupEventDescriptionController: UIViewController {

    @IBOutlet private var eventTitle: UILabel!
    @IBOutlet private var eventLocation: UILabel!
    @IBOutlet private var eventDescription: UILabel!

    var event: CalendarEvent? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.eventTitle.text = self.event?.title
        self.eventLocation.text = self.event?.location
        self.eventDescription.text = self.event?.description
    }
}
