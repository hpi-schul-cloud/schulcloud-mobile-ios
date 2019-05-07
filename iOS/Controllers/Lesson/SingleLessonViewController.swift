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
            return "UnknownCell"
        }
    }
}

class SingleLessonViewController: UITableViewController {

    var content: [LessonContent] = [] {
        didSet {
            for content in self.content {
                guard content.type == .text else { return }
                self.renderedHTMLCache[content.id] = self.htmlHelper.attributedString(for: content.text!)
            }
        }
    }
    let htmlHelper = HTMLHelper.default
    private var renderedHTMLCache: [String: NSAttributedString] = [:]

    let textCellVerticalMargin: CGFloat = 25

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.content.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let content = self.content[indexPath.row]
        switch content.type {
        case .text:
            let attrText = self.renderedHTMLCache[content.id]!
            let width = tableView.readableContentGuide.layoutFrame.width
            let context = NSStringDrawingContext()
            return attrText.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: context).height + textCellVerticalMargin
        default:
            return 44
        }
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
            let textCell = cell as! LessonContentTextCell
            textCell.configure(text: self.renderedHTMLCache[content.id]!)
        }
        return cell
    }
}
