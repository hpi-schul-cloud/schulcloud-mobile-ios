//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

/// TODO(permissions):
///     contentView? Should we not display the content of lesson if no permission? Seems off

fileprivate extension LessonContent.ContentType {
    var cellIdentifier: String {
        switch self {
        case .text:
            return "TextCell"
        case .other:
            fallthrough
        @unknown default:
            return "UnknownCell"
        }
    }
}

class SingleLessonViewController: UITableViewController {

    var content: [LessonContent] = []
    let htmlHelper = HTMLHelper.default

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.content.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = self.content[indexPath.row]
        let cellIdentifier = content.type.cellIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        switch content.type {
        case .other:
            let font = UIFont.italicSystemFont(ofSize: 15.0)
            cell.textLabel?.attributedText = NSAttributedString(string: "This content type isn't supported yet",
                                                      attributes: [NSAttributedString.Key.font: font])
        case .text:
            guard let textCell = cell as? LessonContentTextCell else { fatalError("Unrecognized cell type   ") }
            textCell.textView.attributedText = self.htmlHelper.attributedString(for: content.text!)
            textCell.textView.sizeToFit()
        }

        return cell
    }

}
