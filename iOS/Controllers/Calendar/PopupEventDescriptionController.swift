//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

final class PopupEventDescriptionController: UIViewController {

    @IBOutlet var eventTitle: UILabel!
    @IBOutlet var eventLocation: UILabel!
    @IBOutlet var eventDescription: UITextView!

    var event: CalendarEvent? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.eventTitle.text = self.event?.title
        self.eventLocation.text = self.event?.location
        self.eventDescription.text = self.event?.description
        self.eventDescription.textContainerInset = .zero
        self.eventDescription.textContainer.lineFragmentPadding = 0.0
    }

    func preferredContentHeight(width: CGFloat, for text: String) -> CGFloat {

        let textViewWidth = width - 40.0
        guard textViewWidth > 0.0 else { return .zero }

        let attr = NSMutableAttributedString(string: text)
        attr.setAttributes([.font : UIFont.preferredFont(forTextStyle: .body)], range: NSRange(location: 0, length: text.count))
        let size = attr.boundingRect(with: CGSize(width: textViewWidth,height: CGFloat.greatestFiniteMagnitude),
                                     options: [.usesLineFragmentOrigin],
                                     context: nil).size
        return size.height + 110
    }

    @IBAction func dismissController(_ sender: Any?) {
        self.dismiss(animated: true)
    }
}
